# State Management Documentation

## Overview

This project uses **BLoC pattern** with **Cubit** for state management.

- **Cubit**: Simplified BLoC without events (direct method calls)
- **State**: Immutable data class extending `Equatable`
- **BlocBuilder/BlocConsumer**: Widgets that rebuild on state changes

---

## Cubit Design Principles

### 1. Single Responsibility

Each cubit handles ONE flow/feature:

```
✅ Good:
- LoginCubit (login only)
- SignupCubit (signup + set password)
- ForgotPasswordCubit (forgot password + reset)

❌ Bad:
- AuthCubit (login + signup + forgot password) - too large
```

### 2. Cubit Owns Controllers

TextEditingControllers live in the cubit, not the page:

```dart
class LoginCubit extends Cubit<LoginState> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
```

### 3. Dependency Injection

Dependencies are injected via constructor:

```dart
class LoginCubit extends Cubit<LoginState> {
  final Validators validators;
  final AuthManager authManager;

  LoginCubit({
    required this.validators,
    required this.authManager,
  }) : super(const LoginState());
}
```

---

## State Design

### State Structure

```dart
class LoginState extends Equatable {
  // Loading indicator
  final bool isLoading;
  
  // Field errors
  final String? emailError;
  final String? passwordError;
  
  // General errors
  final String? generalError;
  
  // Derived state
  final bool isButtonEnabled;

  const LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.generalError,
    this.isButtonEnabled = false,
  });

  // copyWith for immutable updates
  LoginState copyWith({
    bool? isLoading,
    String? emailError,
    String? passwordError,
    String? generalError,
    bool? isButtonEnabled,
  }) => LoginState(
    isLoading: isLoading ?? this.isLoading,
    emailError: emailError,  // null clears the error
    passwordError: passwordError,
    generalError: generalError,
    isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
  );

  // Equatable props
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

### State Properties Patterns

| Property Type | Example | Usage |
|---------------|---------|-------|
| Loading | `isLoading: bool` | Show spinner, disable buttons |
| Field Error | `emailError: String?` | Inline error below text field |
| General Error | `generalError: String?` | Toast/snackbar/dialog |
| Button State | `isButtonEnabled: bool` | Enable/disable submit button |
| Data | `vehicles: List<Vehicle>` | Display in list |
| Selected | `selectedVehicle: Vehicle?` | Edit mode |

---

## Cubit Methods

### Validation Method

```dart
void validateEmail() {
  final email = emailController.text.trim();
  final error = validators.validateEmail(email);
  
  emit(state.copyWith(
    emailError: error,
    isButtonEnabled: _canSubmit(),
  ));
}

bool _canSubmit() {
  return emailController.text.isNotEmpty &&
         passwordController.text.isNotEmpty &&
         state.emailError == null &&
         state.passwordError == null;
}
```

### Submit Method

```dart
Future<void> signIn() async {
  // 1. Set loading
  emit(state.copyWith(isLoading: true, generalError: null));
  
  try {
    // 2. Perform operation
    final user = await authManager.signInWithEmail(
      context,
      emailController.text.trim(),
      passwordController.text,
    );
    
    // 3. Success - emit result
    emit(state.copyWith(isLoading: false));
    // Navigation handled in listener
    
  } catch (e) {
    // 4. Error - emit error
    emit(state.copyWith(
      isLoading: false,
      generalError: NetworkExceptions.getSupabaseExceptionMessage(e),
    ));
  }
}
```

---

## Page Integration

### BlocProvider in Router

```dart
case RoutesName.login:
  return MaterialPageRoute(
    builder: (_) => BlocProvider.value(
      value: getIt<LoginCubit>(),  // Singleton cubit
      child: const LoginPage(),
    ),
  );

case RoutesName.vehicleList:
  return MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => getIt<VehicleCubit>()..loadVehicles(),  // Factory cubit
      child: const VehicleListPage(),
    ),
  );
```

### BlocConsumer (UI + Side Effects)

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginCubit, LoginState>(
        // listener: side effects (navigation, snackbar)
        listener: (context, state) {
          if (state.generalError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.generalError!)),
            );
          }
        },
        // builder: UI rendering
        builder: (context, state) {
          return LoginForm(state: state);
        },
      ),
    );
  }
}
```

### BlocBuilder (UI Only)

```dart
BlocBuilder<VehicleCubit, VehicleState>(
  builder: (context, state) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }
    return VehicleList(vehicles: state.vehicles);
  },
)
```

### Accessing Cubit

```dart
// Read: call methods (actions)
context.read<LoginCubit>().signIn();

// Watch: rebuild on changes (in builder)
final cubit = context.watch<LoginCubit>();
```

---

## Complete Cubit Example

```dart
// State
class SignupState extends Equatable {
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? generalError;
  final bool isEmailButtonEnabled;
  final bool isPasswordButtonEnabled;
  final String? signupEmail; // Stored for password step
  final int passwordFieldTrigger; // Force rebuild

  const SignupState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.generalError,
    this.isEmailButtonEnabled = false,
    this.isPasswordButtonEnabled = false,
    this.signupEmail,
    this.passwordFieldTrigger = 0,
  });

  SignupState copyWith({...}) => SignupState(...);

  @override
  List<Object?> get props => [...];
}

// Cubit
class SignupCubit extends Cubit<SignupState> {
  final Validators validators;
  final AuthManager authManager;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  SignupCubit({
    required this.validators,
    required this.authManager,
  }) : super(const SignupState());

  // Validate email step
  void validateEmail() {
    final error = validators.validateEmail(emailController.text.trim());
    emit(state.copyWith(
      emailError: error,
      isEmailButtonEnabled: error == null && emailController.text.isNotEmpty,
    ));
  }

  // Continue to password step
  void continueToPassword() {
    emit(state.copyWith(signupEmail: emailController.text.trim()));
    // Navigation happens in page listener
  }

  // Validate password step
  void validatePassword() {
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;
    
    final passwordError = validators.validatePassword(password);
    final confirmError = password != confirm ? 'Passwords do not match' : null;
    
    emit(state.copyWith(
      passwordError: passwordError,
      confirmPasswordError: confirmError,
      isPasswordButtonEnabled: passwordError == null && 
                               confirmError == null && 
                               password.isNotEmpty,
      passwordFieldTrigger: state.passwordFieldTrigger + 1,
    ));
  }

  // Complete signup
  Future<void> completeSignup() async {
    emit(state.copyWith(isLoading: true, generalError: null));
    try {
      await authManager.createAccountWithEmail(
        context,
        state.signupEmail!,
        passwordController.text,
      );
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        generalError: NetworkExceptions.getSupabaseExceptionMessage(e),
      ));
    }
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    return super.close();
  }
}
```

---

## State Management Checklist

- [ ] State extends `Equatable`
- [ ] All fields are `final`
- [ ] `copyWith` allows null to clear optional fields
- [ ] `props` includes all fields
- [ ] Cubit owns TextEditingControllers
- [ ] Controllers disposed in `close()`
- [ ] Dependencies injected via constructor
- [ ] Loading state during async operations
- [ ] Error state cleared before new operations
- [ ] Use `NetworkExceptions` for error messages
