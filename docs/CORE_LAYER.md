# Core Layer Documentation

The `lib/src/core/` directory contains shared utilities, components, and configurations used across all features.

## Directory Structure

```
lib/src/core/
├── app_style/
│   └── app_theme.dart          # ThemeData configuration
├── config/
│   └── injection.dart          # GetIt dependency injection
├── constants/
│   ├── app_config.dart         # App ID, name, deep link scheme
│   ├── app_icons.dart          # Icon constants
│   ├── colors.dart             # Color palette
│   ├── strings.dart            # UI strings
│   └── text_style.dart         # Text styles
├── helpers/
│   ├── shared_pref_helper.dart # Local storage wrapper
│   └── spacing.dart            # Spacing helpers
├── models/
│   ├── user_model.dart         # User model
│   └── user_app_model.dart     # User-App junction model
├── networking/
│   └── network_exceptions.dart # Centralized error handling
├── routes/
│   ├── names.dart              # Route name constants
│   └── router.dart             # Route configuration
├── services/
│   └── deep_link_service.dart  # Deep link handling
└── widgets/
    ├── common_app_bar.dart     # Standardized app bar
    ├── common_button.dart      # Primary button
    ├── custom_text_field.dart  # Text input with validation
    └── error_dialog.dart       # Error display dialog
```

---

## App Configuration

**File**: `lib/src/core/constants/app_config.dart`

```dart
class AppConfig {
  AppConfig._();

  /// The app ID - must match the `apps` table in Supabase
  static const String appId = 'park_my_whip_resident';

  /// Human-readable app name
  static const String appName = 'Park My Whip - Resident';

  /// Deep link scheme for this app
  static const String deepLinkScheme = 'parkmywhip-resident';
}
```

**Usage**: Used in `SupabaseAuthManager` to verify user belongs to this specific app.

---

## Dependency Injection

**File**: `lib/src/core/config/injection.dart`

Uses **GetIt** for service location pattern.

### Registration Order

```dart
void setupDependencyInjection() {
  // 1. Core dependencies (initialized in main.dart)
  // getIt.registerLazySingleton<SharedPreferences>(() => prefs);
  
  // 2. Helpers (depend on SharedPreferences)
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());

  // 3. Services (depend on helpers)
  getIt.registerLazySingleton<AuthManager>(
    () => SupabaseAuthManager(getIt<SharedPrefHelper>()),
  );

  // 4. Domain (validators, use cases)
  getIt.registerLazySingleton<Validators>(() => Validators());

  // 5. Cubits (depend on services and domain)
  getIt.registerLazySingleton<LoginCubit>(
    () => LoginCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
    ),
  );
}
```

### Registration Types

| Type | Use Case |
|------|----------|
| `registerLazySingleton` | Services, helpers (single instance) |
| `registerFactory` | Cubits that need fresh instance per screen |

### Accessing Dependencies

```dart
// In pages/widgets
final authManager = getIt<AuthManager>();

// In cubit constructors (injected via DI)
class LoginCubit extends Cubit<LoginState> {
  final Validators validators;
  final AuthManager authManager;
  
  LoginCubit({required this.validators, required this.authManager}) : super(...);
}
```

---

## Helpers

### SharedPrefHelper

**File**: `lib/src/core/helpers/shared_pref_helper.dart`

Wrapper for SharedPreferences with typed methods. Uses GetIt to access the `SharedPreferences` singleton (initialized in `main.dart`).

```dart
class SharedPrefHelper {
  SharedPreferences get _prefs => getIt<SharedPreferences>();
  
  Future<void> saveUser(User user) async { ... }
  Future<User?> getUser() async { ... }
  Future<void> clearUser() async { ... }
}
```

**Important**: `SharedPreferences` is registered as a lazy singleton in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => prefs);
  
  setupDependencyInjection();
  // ...
}
```

### Spacing

**File**: `lib/src/core/helpers/spacing.dart`

```dart
Widget verticalSpace(double height) => SizedBox(height: height.h);
Widget horizontalSpace(double width) => SizedBox(width: width.w);
```

**Usage**:
```dart
Column(
  children: [
    Text('Hello'),
    verticalSpace(16),  // 16.h SizedBox
    Text('World'),
  ],
)
```

---

## Services

### Deep Link Error Handler

**File**: `lib/src/core/services/deep_link_error_handler.dart`

**Purpose**: Intercepts password reset deep links BEFORE Supabase processes them to catch expired/invalid links and show user-friendly error pages.

**Why Needed**: Supabase automatically processes deep links when the app opens. If a reset link is expired/invalid, Supabase would fail silently or show generic errors. This handler catches those errors early.

**How It Works**:
1. App opens with deep link (password reset URL)
2. Handler intercepts URL before Supabase processes it
3. Checks for error parameters: `error`, `error_code`, `error_description`
4. If error found → navigate to error page
5. If no error → let Supabase handle normally (PASSWORD_RECOVERY event)

**Common Error Codes**:
- `otp_expired` - Reset link has expired (default 1 hour)
- `invalid_request` - Link is malformed or invalid
- `access_denied` - Link was already used or revoked

**Implementation**:
```dart
class DeepLinkErrorHandler {
  static final _appLinks = AppLinks();

  static void setup() {
    _appLinks.uriLinkStream.listen(
      (uri) {
        AppLogger.deepLink('Deep link received: ${uri.toString()}');

        // Check query parameters for errors
        final hasQueryError = uri.queryParameters.containsKey('error') ||
            uri.queryParameters.containsKey('error_code');

        // Check fragment for errors (Supabase uses fragment for auth)
        bool hasFragmentError = false;
        if (uri.fragment.isNotEmpty) {
          final fragmentParams = Uri.splitQueryString(uri.fragment);
          hasFragmentError = fragmentParams.containsKey('error') ||
              fragmentParams.containsKey('error_code');
        }

        if (hasQueryError || hasFragmentError) {
          final errorCode = uri.queryParameters['error'] ?? 
                           fragmentParams['error'] ?? 
                           'unknown_error';
          final errorDescription = uri.queryParameters['error_description'] ??
                                  fragmentParams['error_description'] ??
                                  'Email link is invalid or has expired';

          AppLogger.auth('Invalid/expired link: $errorCode - $errorDescription');

          // Navigate to error page BEFORE Supabase processes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = AppRouter.navigatorKey.currentContext;
            if (context != null && context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                RoutesName.resetLinkError,
                (route) => false,
              );
            }
          });
        }
      },
      onError: (error) {
        AppLogger.error('Deep link stream error', error: error);
      },
    );
  }
}
```

**Setup in main.dart**:
```dart
void main() async {
  // ... other initialization
  DeepLinkErrorHandler.setup();
  runApp(const ParkMyWhipResidentApp());
}
```

---

### Password Recovery Manager

**File**: `lib/src/core/services/password_recovery_manager.dart`

**Purpose**: Manages password recovery session security to prevent users from being logged in with temporary recovery sessions.

**The Problem**:
When a user clicks a password reset link, Supabase creates a **temporary recovery session** (similar to login) that persists in local storage. If the user closes the app without completing the password reset, they would be auto-logged in to the dashboard with this temporary session on next app launch - a security risk.

**The Solution**:
Track recovery mode with a persistent flag in `SharedPreferences`. The flag survives app restarts and ensures abandoned recovery sessions are properly cleaned up.

**Complete Flow**:
```
1. User requests reset → Supabase sends email with link
2. User clicks link → PASSWORD_RECOVERY event → flag = TRUE
3a. User completes reset → flag = FALSE → stays logged in ✓
3b. User closes app → flag remains TRUE
4. App reopens:
   - Supabase restores recovery session
   - checkAndClearAbandonedRecoverySession() sees flag = TRUE
   - Signs out user
   - getInitialRoute() checks flag = TRUE → routes to login
   - Flag cleared after routing decision
```

**Key Methods**:

1. **checkAndClearAbandonedRecoverySession()**
   - Called on app startup AFTER Supabase.initialize()
   - Checks recovery flag in SharedPreferences
   - If TRUE: signs out user (but doesn't clear flag yet)
   - Flag stays TRUE for getInitialRoute() to check

2. **clearRecoveryFlagAfterRouting()**
   - Called AFTER app builds and routing decision is made
   - Clears the recovery flag to FALSE
   - Prevents flag from persisting unnecessarily

3. **setRecoveryMode(bool isRecovery)**
   - Called when PASSWORD_RECOVERY event fires (TRUE)
   - Called when user completes password reset (FALSE)
   - Saves flag to SharedPreferences

4. **setupAuthListener()**
   - Listens for PASSWORD_RECOVERY auth events
   - Sets flag to TRUE and navigates to reset password page

**Implementation**:
```dart
class PasswordRecoveryManager {
  static Future<void> checkAndClearAbandonedRecoverySession() async {
    final helper = getIt<SharedPrefHelper>();
    final isRecoveryMode = 
        await helper.getBool(SharedPrefStrings.isRecoveryMode) ?? false;

    AppLogger.auth('Recovery mode check - flag value: $isRecoveryMode');

    if (isRecoveryMode) {
      final session = SupabaseConfig.auth.currentSession;
      AppLogger.auth(
        '⚠️ Abandoned recovery session detected! '
        'Session exists: ${session != null}. Signing out user...',
      );

      // Sign out but DON'T clear flag yet (for routing)
      await SupabaseConfig.auth.signOut();

      AppLogger.auth('✓ Recovery session signed out (flag will be cleared after routing)');
    }
  }

  static Future<void> clearRecoveryFlagAfterRouting() async {
    final helper = getIt<SharedPrefHelper>();
    final isRecoveryMode =
        await helper.getBool(SharedPrefStrings.isRecoveryMode) ?? false;

    if (isRecoveryMode) {
      await helper.saveBool(SharedPrefStrings.isRecoveryMode, false);
      AppLogger.auth('✓ Recovery flag cleared after routing');
    }
  }

  static Future<void> setRecoveryMode(bool isRecovery) async {
    final helper = getIt<SharedPrefHelper>();
    await helper.saveBool(SharedPrefStrings.isRecoveryMode, isRecovery);
    AppLogger.auth(
      isRecovery
          ? '🔑 Recovery mode ENABLED - user clicked password reset link'
          : '✓ Recovery mode DISABLED - user completed password reset',
    );
  }

  static void setupAuthListener() {
    SupabaseConfig.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        AppLogger.auth('Auth event: $event | Session exists: ${data.session != null}');

        if (event == AuthChangeEvent.passwordRecovery) {
          AppLogger.auth('🔑 PASSWORD_RECOVERY event - activating recovery mode');
          
          await setRecoveryMode(true);

          final context = AppRouter.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              RoutesName.resetPassword,
              (route) => false,
            );
          }
        }
      },
      onError: (error) {
        AppLogger.error('Auth state change error', error: error);
      },
    );
  }
}
```

**Setup in main.dart**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Setup DI and initialize SharedPrefHelper
  await setupDependencyInjection();
  
  // Step 2: Initialize Supabase (restores session)
  await SupabaseConfig.initialize();
  
  // Step 3: Check for abandoned recovery sessions (signs out)
  await PasswordRecoveryManager.checkAndClearAbandonedRecoverySession();
  
  // Step 4: Setup deep link error handler
  DeepLinkErrorHandler.setup();
  
  // Step 5: Setup auth listener
  PasswordRecoveryManager.setupAuthListener();
  
  // Step 6: Run app (getInitialRoute checks flag)
  runApp(const ParkMyWhipResidentApp());
  
  // Step 7: Clear flag after routing
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await PasswordRecoveryManager.clearRecoveryFlagAfterRouting();
  });
}
```

**Router Integration**:
```dart
// AppRouter.getInitialRoute() checks flag synchronously
static String getInitialRoute() {
  final helper = getIt<SharedPrefHelper>();
  final isRecoveryMode = helper.getBoolSync(SharedPrefStrings.isRecoveryMode) ?? false;
  final session = SupabaseConfig.auth.currentSession;

  // If recovery flag is TRUE, ALWAYS route to login
  if (isRecoveryMode) {
    AppLogger.navigation('⚠️ Recovery flag detected - forcing login route');
    return RoutesName.login;
  }

  if (session != null) {
    return RoutesName.dashboard;
  }

  return RoutesName.login;
}
```

**Why This Works**:
1. **Initialization Order**: Supabase MUST initialize before recovery check so session exists to sign out
2. **Flag Timing**: Flag stays TRUE during routing decision, cleared after
3. **Synchronous Check**: Router uses `getBoolSync()` to avoid race conditions
4. **Session Restoration**: Supabase automatically restores sessions from local storage

**Testing**:
- ✅ Request reset → click link → close app → reopen → should show login page
- ✅ Request reset → click link → complete reset → should stay logged in
- ✅ Click expired link → should show error page
- ✅ Click invalid link → should show error page

---

## Routing

### Route Names

**File**: `lib/src/core/routes/names.dart`

```dart
class RoutesName {
  // Auth
  static const String login = '/login';
  static const String signup = '/signup';
  static const String setPassword = '/set-password';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetLinkSent = '/reset-link-sent';
  static const String resetPassword = '/reset-password';
  static const String passwordResetSuccess = '/password-reset-success';
  
  // Main
  static const String dashboard = '/dashboard';
}
```

### Route Configuration

**File**: `lib/src/core/routes/router.dart`

```dart
class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<LoginCubit>(),
            child: const LoginPage(),
          ),
        );
      // ... more routes
    }
  }
}
```

### Navigation

```dart
// Push named route
Navigator.pushNamed(context, RoutesName.dashboard);

// Push replacement
Navigator.pushReplacementNamed(context, RoutesName.login);

// Pop
Navigator.pop(context);

// Push and remove all
Navigator.pushNamedAndRemoveUntil(
  context,
  RoutesName.dashboard,
  (route) => false,
);
```

---

## Error Handling

**File**: `lib/src/core/networking/network_exceptions.dart`

### Overview

`NetworkExceptions` provides centralized error handling that converts technical Supabase exceptions into user-friendly messages. It extracts clean error messages by removing technical details, class names, and stack traces.

### Usage Patterns

```dart
// Pattern 1: Get error message for state
try {
  await someOperation();
} catch (e) {
  final message = NetworkExceptions.getSupabaseExceptionMessage(e);
  emit(state.copyWith(error: message));
}

// Pattern 2: Show error dialog
try {
  await someOperation();
} catch (e) {
  NetworkExceptions.showErrorDialog(e, title: 'Failed to Save');
}
```

### Error Message Extraction

The `getSupabaseExceptionMessage` method automatically:
- Identifies exception type (Auth, Postgrest, Storage)
- Extracts clean error messages from technical error strings
- Removes verbose details like class names and stack traces
- Returns user-friendly messages

**Example:**
```
Input:  PostgrestException (PostgrestException(message: Could not find column, code: PGRST204, ...))
Output: Database schema error. Please ensure your database structure is up to date.
```

### Error Types Handled

| Exception Type | Error Codes | Example User Messages |
|----------------|-------------|----------------------|
| `AuthException` | Various | Invalid credentials, email not verified, rate limit |
| `PostgrestException` | `23505`, `23503`, `42501`, `PGRST204`, `PGRST116` | Duplicate record, permission denied, schema error |
| `StorageException` | `404`, `401` | File not found, unauthorized, quota exceeded |
| Network errors | Socket exceptions | No internet connection |

### Common PostgreSQL Error Codes

| Code | Meaning | User Message |
|------|---------|--------------|
| `23505` | Unique violation | "This record already exists" |
| `23503` | Foreign key violation | "Cannot delete, referenced by other data" |
| `42501` | Insufficient privilege | "Permission denied (RLS policy)" |
| `PGRST204` | Column not found | "Database schema error" |
| `PGRST116` | Row not found | "Requested data not found" |

---

## Reusable Widgets

### CommonButton

Primary action button with loading state.

```dart
CommonButton(
  text: 'Login',
  isLoading: state.isLoading,
  isEnabled: state.isButtonEnabled,
  onPressed: () => context.read<LoginCubit>().signIn(),
)
```

### CustomTextField

Text input with validation support.

```dart
CustomTextField(
  controller: cubit.emailController,
  hintText: 'Email',
  keyboardType: TextInputType.emailAddress,
  errorText: state.emailError,
  onChanged: (value) => cubit.validateEmail(),
)
```

### CommonAppBar

Standardized app bar with back button.

```dart
Scaffold(
  appBar: const CommonAppBar(
    title: 'Profile',
    showBackButton: true,
  ),
  body: ...,
)
```

### ErrorDialog

Modal dialog for displaying errors.

```dart
showDialog(
  context: context,
  builder: (_) => ErrorDialog(
    title: 'Error',
    errorMessage: 'Something went wrong',
    onDismiss: () => Navigator.pop(context),
  ),
);
```
