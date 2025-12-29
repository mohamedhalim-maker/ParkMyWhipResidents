# Park My Whip Resident App - Architecture

## 📋 Overview

**App**: Park My Whip - Resident  
**Stack**: Flutter + Supabase + BLoC (Cubit)  
**Architecture**: Clean Architecture with feature-based structure  
**Error Handling**: Functional approach using `Either<AppException, T>` from dartz  
**Multi-App**: Users can belong to multiple apps via `user_apps` junction table

> **📚 Detailed Documentation**: See `docs/` folder for comprehensive guides on architecture, features, state management, and more.

---

## 🏗️ Architecture Layers

### 3-Layer Clean Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                         │
│  Pages → Widgets → Cubits → States                          │
│  - StatelessWidget pages with BlocBuilder/BlocConsumer      │
│  - Reusable widget components (extracted as classes)        │
│  - Cubit manages business logic and TextControllers         │
│  - State holds UI state (loading, errors, data)             │
├─────────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                             │
│  Validators, Business Rules                                 │
│  - Input validation (email, password)                       │
│  - Business logic (when complex enough)                     │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER                              │
│  Models, Services, Repositories                             │
│  - Data models with fromJson/toJson/copyWith               │
│  - Service classes for API operations                       │
│  - Repository pattern for data access                       │
│  - AuthManager for authentication abstraction               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 State Management Pattern

### BLoC (Cubit) Architecture

The app uses **Cubit** (simplified BLoC without events) for state management. Here's how it works:

#### 1. **Cubit Structure**

```dart
// Cubit owns controllers and dependencies
class LoginCubit extends Cubit<LoginState> {
  // Dependencies injected via constructor
  final Validators validators;
  final AuthManager authManager;
  
  // Controllers owned by cubit
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  LoginCubit({
    required this.validators,
    required this.authManager,
  }) : super(const LoginState());
  
  // Methods called by UI
  void onFieldChanged() { ... }
  Future<void> validateLoginForm({required BuildContext context}) async { ... }
  
  // Always dispose controllers
  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
```

**Key Principles:**
- ✅ One Cubit per flow (LoginCubit, SignupCubit, ForgotPasswordCubit)
- ✅ Cubit owns TextEditingControllers
- ✅ Dependencies injected via constructor
- ✅ Controllers disposed in `close()`

#### 2. **State Structure**

```dart
// State is immutable, extends Equatable
class LoginState extends Equatable {
  // Loading indicators
  final bool isLoading;
  
  // Field-specific errors
  final String? emailError;
  final String? passwordError;
  
  // General errors (for snackbars/dialogs)
  final String? generalError;
  
  // Button state
  final bool isButtonEnabled;
  
  const LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.generalError,
    this.isButtonEnabled = false,
  });
  
  // copyWith allows immutable updates
  LoginState copyWith({
    bool? isLoading,
    String? emailError,
    String? passwordError,
    String? generalError,
    bool? isButtonEnabled,
  }) => LoginState(
    isLoading: isLoading ?? this.isLoading,
    emailError: emailError, // null clears the error
    passwordError: passwordError,
    generalError: generalError,
    isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
  );
  
  @override
  List<Object?> get props => [
    isLoading,
    emailError,
    passwordError,
    generalError,
    isButtonEnabled,
  ];
}
```

**Key Principles:**
- ✅ All fields are `final` (immutable)
- ✅ Extends `Equatable` for value comparison
- ✅ `copyWith` allows partial updates
- ✅ Nullable fields can be cleared by passing `null`

#### 3. **Page Integration**

```dart
// Pages are StatelessWidget with BlocBuilder
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return Column(
            children: [
              // Access cubit via getIt for actions
              CustomTextField(
                controller: getIt<LoginCubit>().emailController,
                validator: (_) => state.emailError,
                onChanged: (_) => getIt<LoginCubit>().onFieldChanged(),
              ),
              
              // Show error from state
              if (state.generalError != null)
                Text(state.generalError!),
              
              // Button enabled based on state
              CommonButton(
                text: state.isLoading ? 'Logging in...' : 'Login',
                onPressed: () => getIt<LoginCubit>().validateLoginForm(
                  context: context,
                ),
                isEnabled: state.isButtonEnabled && !state.isLoading,
              ),
            ],
          );
        },
      ),
    );
  }
}
```

**Key Principles:**
- ✅ Pages are `StatelessWidget`
- ✅ Use `BlocBuilder` for UI updates
- ✅ Use `BlocConsumer` when you need side effects (navigation, snackbars)
- ✅ Access cubit via `getIt<CubitType>()` for singleton cubits
- ✅ Access state via `builder: (context, state)`

#### 4. **Widget Components**

```dart
// Extract reusable widgets as PUBLIC classes (not functions)
class DontHaveAccountText extends StatelessWidget {
  const DontHaveAccountText({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => getIt<LoginCubit>().navigateToSignupPage(context: context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Don\'t have an account? '),
          Text('Sign up', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

**Key Principles:**
- ✅ Widgets are **classes**, not functions
- ✅ Widgets are **public** (not private `_WidgetName`)
- ✅ Use `const` constructors when possible
- ✅ Keep widgets focused and reusable

---

## 📐 Auth Feature Architecture

### Feature Structure

```
lib/src/features/auth/
├── data/                           # Data Layer
│   ├── auth_constants.dart         # Constants (table names, etc.)
│   ├── auth_manager.dart           # Abstract auth interface
│   ├── supabase_auth_manager.dart  # Supabase implementation
│   ├── user_profile_repository.dart # User data operations
│   ├── user_app_repository.dart    # Multi-app operations
│   └── user_cache_service.dart     # Local caching
│
├── domain/                         # Domain Layer
│   └── validators.dart             # Email, password validation
│
└── presentation/                   # Presentation Layer
    ├── cubit/                      # State Management
    │   ├── login/
    │   │   ├── login_cubit.dart    # Login business logic
    │   │   └── login_state.dart    # Login UI state
    │   ├── signup/
    │   │   ├── signup_cubit.dart   # Signup flow logic
    │   │   └── signup_state.dart   # Signup UI state
    │   └── forgot_password/
    │       ├── forgot_password_cubit.dart
    │       └── forgot_password_state.dart
    │
    ├── pages/                      # Screens
    │   ├── login_page.dart
    │   ├── signup_pages/
    │   │   ├── signup_page.dart
    │   │   ├── set_password_page.dart
    │   │   ├── enter_otp_code_page.dart
    │   │   └── verify_email_page.dart
    │   └── forgot_password_pages/
    │       ├── forgot_password_page.dart
    │       ├── reset_link_sent_page.dart
    │       ├── reset_link_error_page.dart
    │       ├── reset_password_page.dart
    │       └── password_reset_success_page.dart
    │
    └── widgets/                    # Reusable Components
        ├── already_have_account_text.dart
        ├── dont_have_account_text.dart
        ├── forgot_password.dart
        ├── otp_widget.dart
        ├── password_validation_rules.dart
        └── resend_timer_button.dart
```

### How Pages Connect to State Management

#### Login Flow

```
LoginPage (StatelessWidget)
    │
    ├─► BlocBuilder<LoginCubit, LoginState>
    │       │
    │       ├─► Accesses: getIt<LoginCubit>() [singleton]
    │       │   - emailController
    │       │   - passwordController
    │       │   - onFieldChanged()
    │       │   - validateLoginForm()
    │       │
    │       └─► Reads from: LoginState
    │           - isLoading
    │           - emailError
    │           - passwordError
    │           - generalError
    │           - isButtonEnabled
    │
    └─► Widgets:
        ├─► CustomTextField (email)
        ├─► CustomTextField (password)
        ├─► ForgotPassword
        ├─► DontHaveAccountText
        └─► CommonButton
```

**Flow:**
1. User types in email field
2. `onFieldChanged()` called → clears errors, validates form
3. Cubit emits new state with updated `isButtonEnabled`
4. BlocBuilder rebuilds UI with new state
5. User clicks "Login" button
6. `validateLoginForm()` called → sets `isLoading: true`
7. UI shows loading indicator
8. Auth operation completes → navigate to dashboard or show error

#### Signup Flow (Multi-Step)

```
SignupPage                    SetPasswordPage              EnterOtpCodePage
    │                              │                             │
    ├─► BlocBuilder               ├─► BlocBuilder                ├─► BlocBuilder
    │   <SignupCubit,             │   <SignupCubit,              │   <SignupCubit,
    │    SignupState>             │    SignupState>              │    SignupState>
    │                              │                             │
    │   - Email validation        │   - Password validation      │   - OTP verification
    │   - Check user exists       │   - Confirmation match       │   - Resend timer
    │   - Continue button         │   - Create account           │   - Verify OTP
    │                              │   - Send OTP                 │   - Navigate to dashboard
    │                              │                             │
    └─► All share same            └─► SignupCubit               └─► Same cubit instance
        SignupCubit instance          (singleton via getIt)          maintains state
```

**Key Points:**
- All signup pages share the **same SignupCubit instance** (singleton via GetIt)
- Cubit maintains state across page transitions
- Each page reads from the same `SignupState`
- Navigation happens within cubit methods or page listeners

### Router Integration

```dart
// Router provides cubit to pages via BlocProvider
static Route<dynamic> generate(RouteSettings settings) {
  switch (settings.name) {
    case RoutesName.login:
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<LoginCubit>(),  // Singleton
          child: const LoginPage(),
        ),
      );
    
    case RoutesName.signup:
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<SignupCubit>(),  // Singleton
          child: const SignupPage(),
        ),
      );
    
    // All signup pages use the same cubit instance
    case RoutesName.setPassword:
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<SignupCubit>(),  // Same instance!
          child: const SetPasswordPage(),
        ),
      );
  }
}
```

**Key Points:**
- Use `BlocProvider.value` with `getIt<CubitType>()` for singleton cubits
- This ensures the same cubit instance across multiple pages
- Perfect for multi-step flows (signup, onboarding, etc.)

---

## 🔑 Key Design Decisions

### 1. One Cubit Per Flow (Single Responsibility)

**❌ Bad:** One giant `AuthCubit` handling login, signup, forgot password  
**✅ Good:** Separate cubits for each flow

```
LoginCubit           ~95 lines   - Login only
SignupCubit          ~108 lines  - Signup + OTP flow
ForgotPasswordCubit  ~225 lines  - Password reset flow
```

### 2. Singleton vs Factory Cubits

**Singleton** (use `registerLazySingleton`):
- Multi-step flows (signup, onboarding)
- Need to maintain state across pages
- Example: SignupCubit, LoginCubit

**Factory** (use `registerFactory`):
- New instance per screen
- Independent state per usage
- Example: VehicleCubit (when viewing different vehicles)

### 3. Functional Error Handling (Either Pattern)

Instead of try-catch, we use `Either<AppException, T>` from dartz:

```dart
// Data layer returns Either
Future<Either<AppException, User>> signInWithEmail(
  String email,
  String password,
);

// Presentation layer uses fold
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

### 4. Dependency Injection (GetIt)

All dependencies registered in `lib/src/core/config/injection.dart`:

```dart
void setupDependencyInjection() {
  // Helpers first (no dependencies)
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());
  
  // Services depend on helpers
  getIt.registerLazySingleton<AuthManager>(
    () => SupabaseAuthManager(getIt<SharedPrefHelper>()),
  );
  
  // Cubits depend on services (singleton for multi-step flows)
  getIt.registerLazySingleton<LoginCubit>(
    () => LoginCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
    ),
  );
  
  getIt.registerLazySingleton<SignupCubit>(
    () => SignupCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
      loginCubit: getIt<LoginCubit>(),
    ),
  );
}
```

### 5. Navigation in Cubits

Navigation can happen in two places:

**Option 1: In Cubit (with BuildContext parameter)**
```dart
Future<void> validateLoginForm({required BuildContext context}) async {
  // ... validation logic
  
  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed(RoutesName.dashboard);
  }
}
```

**Option 2: In Page Listener (using BlocConsumer)**
```dart
BlocConsumer<LoginCubit, LoginState>(
  listener: (context, state) {
    // Navigate on success
    if (state.isLoginSuccessful) {
      Navigator.of(context).pushReplacementNamed(RoutesName.dashboard);
    }
    
    // Show error snackbar
    if (state.generalError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.generalError!)),
      );
    }
  },
  builder: (context, state) {
    // UI rendering
  },
)
```

**Current Pattern:** We use Option 1 (navigation in cubit) for simplicity.

---

## 📦 Core Layer

### Shared Components

```
lib/src/core/
├── app_style/
│   └── app_theme.dart              # Theme configuration
├── config/
│   └── injection.dart              # GetIt setup
├── constants/
│   ├── app_config.dart             # App ID, name, scheme
│   ├── colors.dart                 # Color palette
│   ├── strings.dart                # UI strings
│   ├── text_style.dart             # Text styles
│   └── app_icons.dart              # Icon constants
├── helpers/
│   ├── app_logger.dart             # Centralized logging
│   ├── shared_pref_helper.dart     # Local storage
│   └── spacing.dart                # verticalSpace(), horizontalSpace()
├── models/
│   ├── user_model.dart             # User with UserApp
│   └── user_app_model.dart         # Multi-app junction table
├── networking/
│   ├── custom_exceptions.dart      # Exception hierarchy
│   └── network_exceptions.dart     # Error mapping
├── routes/
│   ├── names.dart                  # Route constants
│   └── router.dart                 # Route generator
├── services/
│   ├── deep_link_error_handler.dart # Deep link interceptor
│   └── password_recovery_manager.dart # Password reset session
└── widgets/                        # Reusable widgets
    ├── common_app_bar.dart
    ├── common_button.dart
    ├── custom_text_field.dart
    └── error_dialog.dart
```

---

## 🎯 Quick Reference

### Adding a New Page to Auth Feature

1. **Create the page** in `lib/src/features/auth/presentation/pages/`
   ```dart
   class NewAuthPage extends StatelessWidget {
     const NewAuthPage({super.key});
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         body: BlocBuilder<AuthCubit, AuthState>(
           builder: (context, state) {
             // UI here
           },
         ),
       );
     }
   }
   ```

2. **Add route name** in `lib/src/core/routes/names.dart`
   ```dart
   static const String newAuthPage = '/auth/new-page';
   ```

3. **Register route** in `lib/src/core/routes/router.dart`
   ```dart
   case RoutesName.newAuthPage:
     return MaterialPageRoute(
       builder: (_) => BlocProvider.value(
         value: getIt<AuthCubit>(),
         child: const NewAuthPage(),
       ),
     );
   ```

4. **Navigate from cubit or page**
   ```dart
   Navigator.of(context).pushNamed(RoutesName.newAuthPage);
   ```

### Creating Reusable Widgets

1. **Extract as public class** (not function)
2. **Accept parameters** via constructor
3. **Use const** when possible
4. **Document** with `///` comments

```dart
/// A card displaying vehicle information.
/// 
/// Shows make, model, license plate, and color.
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${vehicle.make} ${vehicle.model}'),
        subtitle: Text(vehicle.licensePlate),
        onTap: onTap,
      ),
    );
  }
}
```

---

## 📚 Further Reading

For detailed documentation, see the `docs/` folder:

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | Deep dive into architecture patterns |
| [FEATURE_GUIDE.md](./docs/FEATURE_GUIDE.md) | Step-by-step feature creation |
| [STATE_MANAGEMENT.md](./docs/STATE_MANAGEMENT.md) | Cubit patterns and examples |
| [DESIGN_SYSTEM.md](./docs/DESIGN_SYSTEM.md) | UI components and theming |
| [SUPABASE.md](./docs/SUPABASE.md) | Database schema and multi-app |
| [CONVENTIONS.md](./docs/CONVENTIONS.md) | Coding standards |

---

## ✅ Architecture Checklist

When adding new pages to auth feature:

- [ ] Page is `StatelessWidget`
- [ ] Uses `BlocBuilder` or `BlocConsumer`
- [ ] Accesses cubit via `getIt<CubitType>()`
- [ ] Reads state from `builder: (context, state)`
- [ ] Controllers accessed from cubit, not created in page
- [ ] Widgets extracted as public classes (not functions)
- [ ] Route name added to `RoutesName`
- [ ] Route registered in `AppRouter.generate()`
- [ ] Uses `BlocProvider.value` with existing cubit instance
- [ ] Colors from `AppColors`, never hardcoded
- [ ] Text styles from `Theme.of(context).textTheme`
- [ ] Errors handled via `Either` and `fold()`
- [ ] Navigation uses `RoutesName` constants

---

**Last Updated**: January 2024  
**For AI Agents**: Read `docs/README.md` first, then select relevant docs based on your task.
