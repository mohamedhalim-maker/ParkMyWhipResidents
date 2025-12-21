import 'package:equatable/equatable.dart';

class SignupState extends Equatable {
  final bool isLoading;

  // Signup email step
  final String? emailError;
  final bool isEmailButtonEnabled;
  final String? signupEmail;

  // Email verification
  final bool canResendEmail;
  final int resendCountdownSeconds;

  // Set password step
  final String? passwordError;
  final String? confirmPasswordError;
  final bool isPasswordButtonEnabled;
  final int passwordFieldTrigger;

  const SignupState({
    this.isLoading = false,
    this.emailError,
    this.isEmailButtonEnabled = false,
    this.signupEmail,
    this.canResendEmail = true,
    this.resendCountdownSeconds = 0,
    this.passwordError,
    this.confirmPasswordError,
    this.isPasswordButtonEnabled = false,
    this.passwordFieldTrigger = 0,
  });

  SignupState copyWith({
    bool? isLoading,
    String? emailError,
    bool? isEmailButtonEnabled,
    String? signupEmail,
    bool? canResendEmail,
    int? resendCountdownSeconds,
    String? passwordError,
    String? confirmPasswordError,
    bool? isPasswordButtonEnabled,
    int? passwordFieldTrigger,
  }) =>
      SignupState(
        isLoading: isLoading ?? this.isLoading,
        emailError: emailError,
        isEmailButtonEnabled: isEmailButtonEnabled ?? this.isEmailButtonEnabled,
        signupEmail: signupEmail ?? this.signupEmail,
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
        signupEmail,
        canResendEmail,
        resendCountdownSeconds,
        passwordError,
        confirmPasswordError,
        isPasswordButtonEnabled,
        passwordFieldTrigger,
      ];
}
