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
  // 1. Helpers (no dependencies)
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());

  // 2. Services (depend on helpers)
  getIt.registerLazySingleton<AuthManager>(
    () => SupabaseAuthManager(getIt<SharedPrefHelper>()),
  );

  // 3. Domain (validators, use cases)
  getIt.registerLazySingleton<Validators>(() => Validators());

  // 4. Cubits (depend on services and domain)
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

Wrapper for SharedPreferences with typed methods.

```dart
class SharedPrefHelper {
  Future<void> saveUser(User user) async { ... }
  Future<User?> getUser() async { ... }
  Future<void> clearUser() async { ... }
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

### Error Types Handled

| Exception Type | Example Errors |
|----------------|----------------|
| `AuthException` | Invalid credentials, email not verified, rate limit |
| `PostgrestException` | RLS policy violation, duplicate record, table not found |
| `StorageException` | File not found, unauthorized, quota exceeded |
| Network errors | Socket exception, connection refused |

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
