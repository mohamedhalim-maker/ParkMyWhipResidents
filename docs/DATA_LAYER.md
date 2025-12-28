# Data Layer Documentation

## Overview

The data layer handles:
- Data models (entities)
- Services (API operations)
- Authentication management
- Error handling with Either pattern
- Exception mapping from Supabase to domain exceptions

---

## Models

### Model Structure Pattern

Every model should have:

```dart
class ModelName {
  // 1. Final fields
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 2. Constructor
  const ModelName({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  // 3. fromJson factory
  factory ModelName.fromJson(Map<String, dynamic> json) => ModelName(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  // 4. toJson method
  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // 5. copyWith method
  ModelName copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ModelName(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  // 6. Helper getters (optional)
  String get displayName => ...;
}
```

### User Model

**File**: `lib/src/core/models/user_model.dart`

```dart
class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// User's registration for the current app (from user_apps table)
  final UserApp? userApp;

  // Helper getters
  String get displayName => fullName.isNotEmpty ? fullName : email;
  String get role => userApp?.role ?? 'user';
  bool get isAdmin => role == 'admin';
  bool get isResident => role == 'user' || role == 'resident';
  bool get isRegisteredForApp => userApp != null;
  bool get isActiveInApp => userApp?.isActive ?? false;
}
```

### UserApp Model (Junction Table)

**File**: `lib/src/core/models/user_app_model.dart`

```dart
/// Maps to `user_apps` junction table - links users to apps with roles
class UserApp {
  final String id;
  final String userId;
  final String appId;         // e.g., 'park_my_whip_resident'
  final String role;          // e.g., 'user', 'admin'
  final bool isActive;
  final Map<String, dynamic> appSpecificData;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## Services

### Service Pattern

```dart
class FeatureService {
  static const String _tableName = 'table_name';

  // CRUD operations
  Future<List<Model>> getAll(String userId) async { ... }
  Future<Model> getById(String id) async { ... }
  Future<Model> create(Model model) async { ... }
  Future<Model> update(Model model) async { ... }
  Future<void> delete(String id) async { ... }
}
```

### Supabase Query Patterns

```dart
// SELECT all with filter
final response = await SupabaseConfig.client
    .from('vehicles')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);

// SELECT single
final response = await SupabaseConfig.client
    .from('users')
    .select()
    .eq('id', userId)
    .single();

// SELECT with join
final response = await SupabaseConfig.client
    .from('users')
    .select('*, user_apps!inner(*)')
    .eq('id', userId)
    .eq('user_apps.app_id', AppConfig.appId)
    .single();

// INSERT and return
final response = await SupabaseConfig.client
    .from('vehicles')
    .insert(vehicle.toJson())
    .select()
    .single();

// UPDATE
final response = await SupabaseConfig.client
    .from('vehicles')
    .update({'make': 'Toyota'})
    .eq('id', vehicleId)
    .select()
    .single();

// DELETE
await SupabaseConfig.client
    .from('vehicles')
    .delete()
    .eq('id', vehicleId);

// UPSERT (insert or update)
await SupabaseConfig.client
    .from('users')
    .upsert(user.toJson());
```

---

## Auth Manager

### Interface Design (SOLID)

**File**: `lib/auth/auth_manager.dart`

```dart
/// Base interface for authentication
abstract class AuthManager {
  User? get currentUser;
  bool get isLoggedIn;
  Stream<User?> get userStream;
  Future<void> logout();
}

/// Mixin for email-based authentication
mixin EmailSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithEmail(String email, String password);
  Future<Either<AppException, User>> createAccountWithEmail(String email, String password);
  Future<Either<AppException, Unit>> resendVerificationEmail({required String email});
  Future<Either<AppException, User>> verifyOtpWithEmail({required String email, required String otpCode});
  Future<Either<AppException, SignupEligibilityResult>> checkSignupEligibility(String email);
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> resetPassword(String newPassword);
  Future<void> resendVerificationEmail(String email);
}

/// Future mixins for other auth methods
// mixin GoogleSignInManager on AuthManager { ... }
// mixin AppleSignInManager on AuthManager { ... }
```

### Implementation

**File**: `lib/auth/supabase_auth_manager.dart`

```dart
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  final SharedPrefHelper _sharedPrefHelper;
  User? _currentUser;

  @override
  Future<User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      // 1. Authenticate with Supabase Auth
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 2. Verify user is registered for THIS app
      final userApp = await _getUserAppRegistration(response.user!.id);
      if (userApp == null) {
        await SupabaseConfig.auth.signOut();
        throw Exception('Your account is not registered for this app.');
      }

      // 3. Fetch full user profile
      final user = await _getUserProfile(response.user!.id, userApp: userApp);
      
      // 4. Cache locally
      await _cacheUser(user);
      
      return user;
    } on AuthException catch (e) {
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }
}
```

---

## Error Handling

### Either Pattern (Functional Error Handling)

All data layer methods return `Either<AppException, T>` from the `dartz` package:

```dart
// ✅ Good - Returns Either
Future<Either<AppException, User>> signInWithEmail(
  String email,
  String password,
) async {
  try {
    final response = await SupabaseConfig.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      return left(const AuthenticationException(
        message: 'Login failed. Please try again.',
      ));
    }
    
    final user = await _fetchUserProfile(response.user!.id);
    return right(user);  // Success
  } catch (e) {
    return left(SupabaseExceptionMapper.map(e));  // Error
  }
}

// ❌ Bad - Throws exceptions
Future<User> signInWithEmail(String email, String password) async {
  throw Exception('Login failed');  // Don't do this!
}
```

### AppException Hierarchy

**File**: `lib/src/core/networking/custom_exceptions.dart`

```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });
}

class AuthenticationException extends AppException { ... }
class DatabaseException extends AppException { ... }
class NetworkException extends AppException { ... }
class StorageException extends AppException { ... }
class UnknownException extends AppException { ... }
```

### SupabaseExceptionMapper

**File**: `lib/src/core/networking/network_exceptions.dart`

Converts Supabase-specific exceptions to domain exceptions:

```dart
class SupabaseExceptionMapper {
  static AppException map(dynamic error) {
    // Already mapped
    if (error is AppException) return error;
    
    // Network errors
    if (error is SocketException) {
      return NetworkException(
        message: 'No internet connection',
        originalError: error,
      );
    }
    
    // Supabase Auth errors
    if (error is supabase.AuthException) {
      return _mapAuthException(error);
    }
    
    // Supabase Database errors
    if (error is supabase.PostgrestException) {
      return _mapDatabaseException(error);
    }
    
    // Supabase Storage errors
    if (error is supabase.StorageException) {
      return _mapStorageException(error);
    }
    
    // Unknown errors
    return UnknownException(
      message: error.toString(),
      originalError: error,
    );
  }
  
  static AuthenticationException _mapAuthException(
    supabase.AuthException error,
  ) {
    // Map common auth errors to user-friendly messages
    final message = error.message.toLowerCase().contains('invalid login')
        ? 'Invalid email or password'
        : error.message;
        
    return AuthenticationException(
      message: message,
      code: error.statusCode,
      originalError: error,
    );
  }
}
```

### Error Handling in Data Layer

```dart
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  @override
  Future<Either<AppException, User>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      // Step 1: Authenticate
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return left(
          const AuthenticationException(
            message: 'Login failed. Please try again.',
          ),
        );
      }

      // Step 2: Fetch user data
      final user = await _userProfileRepository.getUserProfile(
        response.user!.id,
      );

      if (user == null) {
        return left(
          const DatabaseException(
            message: 'Failed to load user profile.',
          ),
        );
      }

      // Step 3: Return success
      return right(user);
    } catch (e) {
      // Convert any exception to AppException
      return left(SupabaseExceptionMapper.map(e));
    }
  }

  @override
  Future<Either<AppException, Unit>> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      await _cacheService.clearCache();
      return right(unit);  // unit is from dartz for void
    } catch (e) {
      return left(SupabaseExceptionMapper.map(e));
    }
  }
}
```

### Common Error Mapping Patterns

| Supabase Error | User-Friendly Message | Exception Type |
|----------------|----------------------|----------------|
| `invalid login credentials` | `Invalid email or password` | AuthenticationException |
| `email not confirmed` | `Please verify your email address` | AuthenticationException |
| `User already registered` | `This email is already registered` | AuthenticationException |
| `23505` (unique violation) | `This record already exists` | DatabaseException |
| `42501` (permission denied) | `You don't have permission` | DatabaseException |
| Socket timeout | `No internet connection` | NetworkException |

---

## NetworkExceptions Class (Legacy - Being Replaced)

> **Note**: This class is being phased out in favor of `SupabaseExceptionMapper`. Use the Either pattern for new code.

**File**: `lib/src/core/networking/network_exceptions.dart`

```dart
abstract class NetworkExceptions {
  /// Legacy method - use SupabaseExceptionMapper instead
  static String getSupabaseExceptionMessage(dynamic error) {
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }
    if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    }
    return 'An unexpected error occurred.';
  }
}
```

---

## Local Caching

### SharedPrefHelper

```dart
class SharedPrefHelper {
  static const String _userKey = 'cached_user';
  
  // SharedPreferences is injected via GetIt (initialized in main.dart)
  SharedPreferences get _prefs => getIt<SharedPreferences>();

  Future<void> saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final json = _prefs.getString(_userKey);
    if (json == null) return null;
    return User.fromJson(jsonDecode(json));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }
}
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION                             │
│  Page → Cubit → emit(state.copyWith(isLoading: true))           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                           SERVICE                                │
│  await SupabaseConfig.client.from('table').select()             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          SUPABASE                                │
│  PostgreSQL Database                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                           MODEL                                  │
│  Model.fromJson(response) → User, Vehicle, etc.                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION                             │
│  emit(state.copyWith(data: model, isLoading: false))            │
└─────────────────────────────────────────────────────────────────┘
```
