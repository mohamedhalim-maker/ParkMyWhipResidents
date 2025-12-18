import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isLoginMode;
  final bool isLoading;
  final bool isButtonEnabled;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? firstNameError;
  final String? lastNameError;
  final String? errorMessage;
  final String? successMessage;
  final String? loginEmailError;
  final String? loginPasswordError;
  final String? loginGeneralError;
  final bool isLoginButtonEnabled;
  
  // Forgot password flow properties
  final String? forgotPasswordEmailError;
  final bool isForgotPasswordButtonEnabled;
  final bool canResendEmail;
  final int resendCountdownSeconds;
  
  // Reset password flow properties
  final String? resetPasswordError;
  final String? resetConfirmPasswordError;
  final bool isResetPasswordButtonEnabled;
  final int resetPasswordFieldTrigger;

  const AuthState({
    this.isLoginMode = true,
    this.isLoading = false,
    this.isButtonEnabled = false,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.firstNameError,
    this.lastNameError,
    this.errorMessage,
    this.successMessage,
    this.loginEmailError,
    this.loginPasswordError,
    this.loginGeneralError,
    this.isLoginButtonEnabled = false,
    this.forgotPasswordEmailError,
    this.isForgotPasswordButtonEnabled = false,
    this.canResendEmail = false,
    this.resendCountdownSeconds = 0,
    this.resetPasswordError,
    this.resetConfirmPasswordError,
    this.isResetPasswordButtonEnabled = false,
    this.resetPasswordFieldTrigger = 0,
  });

  AuthState copyWith({
    bool? isLoginMode,
    bool? isLoading,
    bool? isButtonEnabled,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? firstNameError,
    String? lastNameError,
    String? errorMessage,
    String? successMessage,
    String? loginEmailError,
    String? loginPasswordError,
    String? loginGeneralError,
    bool? isLoginButtonEnabled,
    String? forgotPasswordEmailError,
    bool? isForgotPasswordButtonEnabled,
    bool? canResendEmail,
    int? resendCountdownSeconds,
    String? resetPasswordError,
    String? resetConfirmPasswordError,
    bool? isResetPasswordButtonEnabled,
    int? resetPasswordFieldTrigger,
  }) => AuthState(
    isLoginMode: isLoginMode ?? this.isLoginMode,
    isLoading: isLoading ?? this.isLoading,
    isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
    emailError: emailError ?? this.emailError,
    passwordError: passwordError ?? this.passwordError,
    confirmPasswordError: confirmPasswordError ?? this.confirmPasswordError,
    firstNameError: firstNameError ?? this.firstNameError,
    lastNameError: lastNameError ?? this.lastNameError,
    errorMessage: errorMessage,
    successMessage: successMessage,
    loginEmailError: loginEmailError,
    loginPasswordError: loginPasswordError,
    loginGeneralError: loginGeneralError,
    isLoginButtonEnabled: isLoginButtonEnabled ?? this.isLoginButtonEnabled,
    forgotPasswordEmailError: forgotPasswordEmailError,
    isForgotPasswordButtonEnabled: isForgotPasswordButtonEnabled ?? this.isForgotPasswordButtonEnabled,
    canResendEmail: canResendEmail ?? this.canResendEmail,
    resendCountdownSeconds: resendCountdownSeconds ?? this.resendCountdownSeconds,
    resetPasswordError: resetPasswordError,
    resetConfirmPasswordError: resetConfirmPasswordError,
    isResetPasswordButtonEnabled: isResetPasswordButtonEnabled ?? this.isResetPasswordButtonEnabled,
    resetPasswordFieldTrigger: resetPasswordFieldTrigger ?? this.resetPasswordFieldTrigger,
  );

  @override
  List<Object?> get props => [
    isLoginMode,
    isLoading,
    isButtonEnabled,
    emailError,
    passwordError,
    confirmPasswordError,
    firstNameError,
    lastNameError,
    errorMessage,
    successMessage,
    loginEmailError,
    loginPasswordError,
    loginGeneralError,
    isLoginButtonEnabled,
    forgotPasswordEmailError,
    isForgotPasswordButtonEnabled,
    canResendEmail,
    resendCountdownSeconds,
    resetPasswordError,
    resetConfirmPasswordError,
    isResetPasswordButtonEnabled,
    resetPasswordFieldTrigger,
  ];
}
