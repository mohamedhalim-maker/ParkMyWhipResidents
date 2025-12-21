import 'package:equatable/equatable.dart';

class ForgotPasswordState extends Equatable {
  final bool isLoading;

  // Forgot password email step
  final String? emailError;
  final bool isEmailButtonEnabled;
  final bool canResendEmail;
  final int resendCountdownSeconds;

  // Reset password step
  final String? passwordError;
  final String? confirmPasswordError;
  final bool isPasswordButtonEnabled;
  final int passwordFieldTrigger;

  const ForgotPasswordState({
    this.isLoading = false,
    this.emailError,
    this.isEmailButtonEnabled = false,
    this.canResendEmail = false,
    this.resendCountdownSeconds = 0,
    this.passwordError,
    this.confirmPasswordError,
    this.isPasswordButtonEnabled = false,
    this.passwordFieldTrigger = 0,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? emailError,
    bool? isEmailButtonEnabled,
    bool? canResendEmail,
    int? resendCountdownSeconds,
    String? passwordError,
    String? confirmPasswordError,
    bool? isPasswordButtonEnabled,
    int? passwordFieldTrigger,
  }) =>
      ForgotPasswordState(
        isLoading: isLoading ?? this.isLoading,
        emailError: emailError,
        isEmailButtonEnabled: isEmailButtonEnabled ?? this.isEmailButtonEnabled,
        canResendEmail: canResendEmail ?? this.canResendEmail,
        resendCountdownSeconds:
            resendCountdownSeconds ?? this.resendCountdownSeconds,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
        isPasswordButtonEnabled:
            isPasswordButtonEnabled ?? this.isPasswordButtonEnabled,
        passwordFieldTrigger: passwordFieldTrigger ?? this.passwordFieldTrigger,
      );

  @override
  List<Object?> get props => [
        isLoading,
        emailError,
        isEmailButtonEnabled,
        canResendEmail,
        resendCountdownSeconds,
        passwordError,
        confirmPasswordError,
        isPasswordButtonEnabled,
        passwordFieldTrigger,
      ];
}
