# Data Layer Documentation

## Overview

The data layer handles:
- Data models (entities)
- Services (API operations)
- Authentication management
- Error translation

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
  Future<User?> signInWithEmail(BuildContext context, String email, String password);
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

### NetworkExceptions Class

**File**: `lib/src/core/networking/network_exceptions.dart`

Translates technical errors to user-friendly messages.

```dart
abstract class NetworkExceptions {
  /// Main entry point - handles all Supabase exception types
  static String getSupabaseExceptionMessage(dynamic error) {
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }
    if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    }
    if (error is StorageException) {
      return _getStorageErrorMessage(error);
    }
    return 'An unexpected error occurred.';
  }

  /// Shows error in a dialog
  static void showErrorDialog(dynamic error, {String? title}) { ... }
}
```

### Error Message Mapping

| Error Pattern | User Message |
|---------------|--------------|
| `invalid login credentials` | "Invalid email or password..." |
| `email not confirmed` | "Please verify your email address..." |
| `user already registered` | "This email is already registered..." |
| `42501` (Postgres) | "Permission denied..." |
| `23505` (Postgres) | "This record already exists..." |

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
