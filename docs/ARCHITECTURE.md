# Architecture Overview

## Architectural Pattern

This project follows **Clean Architecture** with **BLoC pattern** for state management.

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  (Pages, Widgets, Cubits)                                   │
│  - UI rendering                                             │
│  - User interaction handling                                │
│  - State management via Cubit                               │
├─────────────────────────────────────────────────────────────┤
│                       DOMAIN LAYER                           │
│  (Validators, Business Logic)                               │
│  - Validation rules                                         │
│  - Business entities                                        │
│  - Use cases (when needed)                                  │
├─────────────────────────────────────────────────────────────┤
│                        DATA LAYER                            │
│  (Models, Services, Auth Manager)                           │
│  - Data models with fromJson/toJson                         │
│  - API calls to Supabase                                    │
│  - Local caching with SharedPreferences                     │
└─────────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### Presentation Layer
- **Pages**: StatelessWidgets that use `BlocBuilder`/`BlocConsumer`
- **Widgets**: Reusable UI components (no business logic)
- **Cubits**: State management, holds TextControllers, emits states

### Domain Layer  
- **Validators**: Input validation (email, password rules)
- **Use Cases**: Complex business operations (future)

### Data Layer
- **Models**: Data structures with serialization
- **Services**: API operations (CRUD)
- **Auth Manager**: Authentication abstraction

## Error Handling

This project uses **functional error handling** with the `dartz` package for clean, type-safe error management.

### Either Pattern

All data layer operations return `Either<AppException, T>`:

```dart
// Data layer returns Either
Future<Either<AppException, User>> signInWithEmail(
  String email,
  String password,
);

// Presentation layer uses fold to handle results
final result = await authManager.signInWithEmail(email, password);

result.fold(
  (error) {
    // Handle error - Left side
    emit(state.copyWith(
      isLoading: false,
      generalError: error.message,
    ));
  },
  (user) {
    // Handle success - Right side
    emit(state.copyWith(isLoading: false));
    navigateToDashboard();
  },
);
```

### Exception Hierarchy

**File**: `lib/src/core/networking/custom_exceptions.dart`

```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
}

class AuthenticationException extends AppException { ... }
class DatabaseException extends AppException { ... }
class NetworkException extends AppException { ... }
class StorageException extends AppException { ... }
class UnknownException extends AppException { ... }
```

### Exception Mapping

**File**: `lib/src/core/networking/network_exceptions.dart`

```dart
class SupabaseExceptionMapper {
  static AppException map(dynamic error) {
    if (error is AppException) return error;
    if (error is SocketException) return NetworkException(...);
    if (error is supabase.AuthException) return _mapAuthException(error);
    if (error is supabase.PostgrestException) return _mapDatabaseException(error);
    return UnknownException(...);
  }
}
```

### Error Handling Rules

**✅ DO:**
- Return `Either<AppException, T>` from data layer
- Use `fold()` in presentation layer
- Use `SupabaseExceptionMapper.map()` to convert exceptions
- Return `Right(value)` for success, `Left(exception)` for errors
- Use `unit` from dartz for void returns: `Right(unit)`

**❌ DON'T:**
- Use try-catch in presentation layer (cubits)
- Throw exceptions from data layer methods
- Return nullable types when using Either
- Mix exception throwing with Either pattern

## Logging

Use `AppLogger` from `lib/src/core/helpers/app_logger.dart` for all logging instead of `print()` or `debugPrint()`.

```dart
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';

// General logging
AppLogger.info('User logged in successfully');
AppLogger.debug('Processing item: $itemId');
AppLogger.warning('Rate limit approaching');
AppLogger.error('Failed to fetch data', error: e, stackTrace: stackTrace);

// Domain-specific logging
AppLogger.deepLink('Received deep link: $uri');
AppLogger.auth('Auth state changed: $event');
AppLogger.navigation('Navigating to: $route');
```

Benefits over print/debugPrint:
- Categorized logs with named channels
- Log levels for filtering
- Proper error and stack trace handling
- Consistent format across the app

## Key Design Decisions

### 1. One Cubit Per Flow (Single Responsibility)

**Bad**: One giant `AuthCubit` handling login, signup, forgot password  
**Good**: Separate `LoginCubit`, `SignupCubit`, `ForgotPasswordCubit`

```dart
// Each cubit is focused and maintainable
class LoginCubit extends Cubit<LoginState> { ... }      // ~95 lines
class SignupCubit extends Cubit<SignupState> { ... }    // ~108 lines
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> { ... } // ~225 lines
```

### 2. Dependency Injection with GetIt

All dependencies are registered in `injection.dart`:

```dart
void setupDependencyInjection() {
  // Helpers first (no dependencies)
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());
  
  // Services depend on helpers
  getIt.registerLazySingleton<AuthManager>(
    () => SupabaseAuthManager(getIt<SharedPrefHelper>()),
  );
  
  // Cubits depend on services
  getIt.registerLazySingleton<LoginCubit>(
    () => LoginCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
    ),
  );
}
```

### 3. Centralized Error Handling

All Supabase errors go through `NetworkExceptions`:

```dart
try {
  await someSupabaseOperation();
} catch (e) {
  // Option 1: Get error message for inline display
  final message = NetworkExceptions.getSupabaseExceptionMessage(e);
  emit(state.copyWith(generalError: message));
  
  // Option 2: Show error dialog
  NetworkExceptions.showErrorDialog(e);
}
```

### 4. Interface-Based Auth (Open/Closed Principle)

```dart
// Abstract interface
abstract class AuthManager {
  User? get currentUser;
  bool get isLoggedIn;
  Future<void> logout();
}

// Mixin for email auth
mixin EmailSignInManager on AuthManager {
  Future<User?> signInWithEmail(BuildContext context, String email, String password);
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password);
}

// Implementation
class SupabaseAuthManager extends AuthManager with EmailSignInManager { ... }
```

### 5. Deep Link Handling (Supabase Native Pattern)

The app uses the **Official Supabase Pattern** combined with a **Deep Link Error Interceptor**.

**Problem solved**:
1. Supabase automatically handles valid deep links but doesn't always trigger events for expired/invalid links.
2. Flutter tries to navigate to deep link paths (e.g., `/?code=...`) which don't exist as routes.

**Solution**:
1. **DeepLinkErrorHandler**: Intercepts links *first* to catch errors (expired tokens) and show the error page.
2. **AppRouter**: Shows a loading indicator for deep link paths (`code=`, `token=`) while Supabase processes them in the background.
3. **Auth Listener**: Reacts to successful `PASSWORD_RECOVERY` events to show the reset password page.

```
┌─────────────────────────────────────────────────────────────┐
│                    DEEP LINK FLOW                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User clicks link ──► DeepLinkErrorHandler (Interceptor)    │
│                               │                             │
│           ┌───────────────────┴───────────────────┐         │
│           ▼                                       ▼         │
│     Error Params?                           No Errors       │
│   (expired/invalid)                             │           │
│           │                                     ▼           │
│           ▼                           Supabase Processes    │
│   Navigate to                                   │           │
│   ResetLinkErrorPage                            ▼           │
│                                       PASSWORD_RECOVERY     │
│                                             Event           │
│                                                 │           │
│                                                 ▼           │
│                                           Navigate to       │
│                                         ResetPasswordPage   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Components**:

1. **DeepLinkErrorHandler** (`lib/src/core/services/deep_link_error_handler.dart`):
   - Initializes in `main.dart`.
   - Listens to `AppLinks` stream.
   - Checks for `error`, `error_code`, or `error_description` in URL query/fragment.
   - Navigates to `RoutesName.resetLinkError` if errors are found.

2. **ParkMyWhipResidentApp** (`lib/park_my_whip_resident_app.dart`):
   - Listens to `SupabaseConfig.auth.onAuthStateChange`.
   - Handles `AuthChangeEvent.passwordRecovery` by navigating to `RoutesName.resetPassword`.

3. **AppRouter** (`lib/src/core/routes/router.dart`):
   - Handles "unknown" routes that look like deep links (contain `code=`, `token=`).
   - Returns a `Scaffold` with `CircularProgressIndicator` to show loading state while Supabase processes the link.

**Error Handling for Deep Links**:

```dart
// Deep link with error parameters:
// parkmywhip-resident://reset-password?error=access_denied&error_code=otp_expired
// -> Caught by DeepLinkErrorHandler -> ResetLinkErrorPage

// The handler detects these errors and navigates to ResetLinkErrorPage
if (uri.queryParameters.containsKey('error') || 
    uri.fragment.contains('error=')) {
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    RoutesName.resetLinkError, 
    (route) => false
  );
}
```

**Initial vs Runtime Deep Links**:

| Type | Scenario | Handling |
|------|----------|----------|
| Initial | App opened via deep link | `DeepLinkErrorHandler` checks for errors, or Supabase triggers auth event |
| Runtime | Deep link while app running | Same flow: Interceptor -> Supabase Event |

**Password Recovery Session Management**:

To prevent users from remaining logged in if they abandon the password reset flow (security best practice):
1. **Flagging**: When `PASSWORD_RECOVERY` event occurs, a flag `SharedPrefStrings.isRecoveryMode` is set in `SharedPreferences`.
2. **Clearing**: When the password is successfully updated, the flag is cleared.
3. **Enforcement**: On app launch (`main.dart`), if `SharedPrefStrings.isRecoveryMode` is true, the user is signed out immediately.

## Project Structure

```
lib/
├── main.dart                           # App entry, initialization
├── park_my_whip_resident_app.dart      # MaterialApp configuration
│
├── auth/                               # Auth abstraction
│   ├── auth_manager.dart               # Abstract interface
│   └── supabase_auth_manager.dart      # Supabase implementation
│
├── supabase/
│   └── supabase_config.dart            # Supabase client initialization
│
└── src/
    ├── core/                           # Shared across features
    │   ├── app_style/
    │   │   └── app_theme.dart          # ThemeData configuration
    │   ├── config/
    │   │   └── injection.dart          # GetIt DI setup
    │   ├── constants/
    │   │   ├── app_config.dart         # App ID, name, deep link scheme
    │   │   ├── colors.dart             # Color palette
    │   │   ├── strings.dart            # UI strings
    │   │   └── text_style.dart         # Text styles
    │   ├── helpers/
    │   │   ├── app_logger.dart         # Centralized logging utility
    │   │   ├── shared_pref_helper.dart # Local storage
    │   │   └── spacing.dart            # verticalSpace(), horizontalSpace()
    │   ├── models/
    │   │   ├── user_model.dart         # User with UserApp relationship
    │   │   └── user_app_model.dart     # user_apps junction table model
    │   ├── networking/
    │   │   └── network_exceptions.dart # Centralized error handling
    │   ├── routes/
    │   │   ├── names.dart              # Route name constants
    │   │   └── router.dart             # Route definitions
    │   ├── services/
    │   │   └── deep_link_service.dart  # Deep link handling
    │   └── widgets/                    # Reusable widgets
    │       ├── common_button.dart
    │       ├── common_app_bar.dart
    │       ├── custom_text_field.dart
    │       └── error_dialog.dart
    │
    └── features/                       # Feature modules
        ├── auth/
        │   ├── domain/
        │   │   └── validators.dart     # Email, password validation
        │   └── presentation/
        │       ├── cubit/
        │       │   ├── login/          # LoginCubit, LoginState
        │       │   ├── signup/         # SignupCubit, SignupState
        │       │   └── forgot_password/ # ForgotPasswordCubit, ForgotPasswordState
        │       ├── pages/
        │       │   ├── login_page.dart
        │       │   ├── signup_pages/
        │       │   └── forgot_password_pages/
        │       └── widgets/            # Auth-specific widgets
        │
        ├── dashboard/
        │   └── presentation/
        │       └── pages/
        │           └── dashboard_page.dart
        │
        └── splash/
            └── presentation/
                └── pages/
                    └── splash_page.dart  # Initial route, waits for deep links
```

## Data Flow

```
User Action → Page → Cubit → Service/AuthManager → Supabase
                ↓
            State Update ← Cubit ← Response
                ↓
            UI Rebuild (BlocBuilder)
```

**Example: Login Flow**

```
┌─────────────────────────────────────────────────────────────┐
│                     LOGIN FLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  LoginPage (enter email & password)                          │
│       │                                                     │
│       ▼                                                     │
│  validateLoginForm() ──► Check email/password format         │
│       │                                                     │
│       ├─── Invalid ──► Show field errors                    │
│       │                                                     │
│       ▼                                                     │
│  signInWithEmail(email, password)                           │
│       │                                                     │
│       ├─── Step 1: Pre-Auth Validation                      │
│       │    Call RPC: get_user_by_email_with_app_check       │
│       │    ├─── user: null ──► "Account not found"          │
│       │    ├─── user_app: null ──► "Not registered"         │
│       │    └─── user_app.is_active: false ──► "Deactivated" │
│       │                                                     │
│       ├─── Step 2: Authenticate                             │
│       │    auth.signInWithPassword()                        │
│       │                                                     │
│       ├─── Step 3: Fetch User Data                          │
│       │    getUserProfile() & getUserAppRegistration()      │
│       │                                                     │
│       ├─── Success ──► Cache user ──► Dashboard             │
│       │                                                     │
│       └─── Error ──► Show error message                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Components**:
1. **LoginCubit** manages form validation and login state
2. **Pre-Authentication Check** uses RPC `get_user_by_email_with_app_check` to validate app access BEFORE authentication
3. **No Auto-Creation** - Users MUST complete signup first; login does not create missing records
4. **RPC Response** returns `{user: {...}, user_app: {...}}` for valid access
5. **NetworkExceptions** handles all Supabase errors centrally

**Pre-Auth Validation Scenarios**:
| `user` | `user_app` | `is_active` | Action |
|--------|------------|-------------|--------|
| `null` | `null` | N/A | Error: "Account not found. Please sign up first." |
| `exists` | `null` | N/A | Error: "Not registered for this app. Please contact support." |
| `exists` | `exists` | `false` | Error: "Account deactivated. Please contact support." |
| `exists` | `exists` | `true` | ✅ Proceed to authentication |

**Security Benefits**:
- Validates app access before consuming authentication attempts
- Prevents cross-app unauthorized access in multi-app architecture
- Users from other apps using same Supabase instance cannot login
- Clear error messages guide users appropriately

**Example: Signup with OTP Verification Flow (Multi-App Architecture)**

```
┌─────────────────────────────────────────────────────────────┐
│                   SIGNUP OTP FLOW                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SignupPage (enter email)                                   │
│       │                                                     │
│       ▼                                                     │
│  validateEmailForm() ──► RPC: check_user_and_grant_app_access│
│       │                                                     │
│       ├─── status: 'exists_this_app'                        │
│       │    └─► Error: "Already registered. Please sign in." │
│       │                                                     │
│       ├─── status: 'granted_access' (cross-app user)        │
│       │    └─► RPC creates user_apps record                 │
│       │    └─► Prefill LoginCubit with email & error        │
│       │    └─► Navigate to LoginPage                        │
│       │                                                     │
│       └─── status: 'new_user'                               │
│            └─► Navigate to SetPasswordPage                  │
│                     │                                       │
│                     ▼                                       │
│           createAccountWithEmail() ──► Supabase sends OTP   │
│                     │              (creates auth.users)     │
│                     ▼                                       │
│           EnterOtpCodePage (user enters 6-digit code)       │
│                     │                                       │
│                     ▼                                       │
│           verifyOtpWithEmail(email, otp)                    │
│                     │                                       │
│                     ├─── OTP Valid ──► RPC function         │
│                     │    create_user_profile_on_first_login │
│                     │    └─► Creates users record           │
│                     │    └─► Creates user_apps record       │
│                     │    └─► Returns user data              │
│                     │                                       │
│                     ├─── Success ──► Cache user ──► Dashboard│
│                     │                                       │
│                     └─── Error ──► Show error, allow resend │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Cross-App Signup Scenarios:**

| Scenario | RPC Status | Action |
|----------|------------|--------|
| New user (no account) | `new_user` | Continue to password page |
| User exists for THIS app | `exists_this_app` | Error: "Already registered" |
| User exists for OTHER app | `granted_access` | Create user_apps → Navigate to login |

Key components:
1. **SignupCubit** manages the entire signup flow including cross-app detection
2. **RPC `check_user_and_grant_app_access`** checks user status BEFORE signup and grants access for cross-app users
3. **LoginCubit.prefillForCrossAppSignup()** prefills email and shows error message for cross-app users
4. **Supabase** automatically sends 6-digit OTP on `signUp()` call (creates `auth.users` record)
5. **verifyOTP** with `OtpType.signup` verifies the code and logs user in
6. **RPC Function** `create_user_profile_on_first_login` creates `users` and `user_apps` records (bypasses RLS)
7. User is auto-logged in after successful OTP verification with complete profile
8. Resend OTP uses `signInWithOtp()` method with 60-second cooldown

**Important:** Database records (`users` and `user_apps`) are ONLY created after successful OTP verification, not during initial signup. This prevents orphaned records for unverified users.
