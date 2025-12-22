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
        └── dashboard/
            └── presentation/
                └── pages/
                    └── dashboard_page.dart
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

1. User taps "Login" button
2. `LoginPage` calls `context.read<LoginCubit>().signIn()`
3. `LoginCubit` validates input, emits `isLoading: true`
4. `LoginCubit` calls `authManager.signInWithEmail()`
5. `SupabaseAuthManager` calls Supabase Auth API
6. On success: Cache user, return User object
7. `LoginCubit` emits success state
8. `BlocConsumer.listener` navigates to Dashboard
