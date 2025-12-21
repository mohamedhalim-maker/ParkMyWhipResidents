import 'package:equatable/equatable.dart';

class SignupState extends Equatable {
  final bool isLoading;

  // Signup email step
  final String? emailError;
  final bool isEmailButtonEnabled;
  final String? signupEmail;

  // Email verification timer
  final bool canResendEmail;
  final int resendCountdownSeconds;
  final bool isTimerRunning;

  // Set password step
  final String? passwordError;
  final String? confirmPasswordError;
  final String? generalError;
  final bool isPasswordButtonEnabled;
  final int passwordFieldTrigger;

  const SignupState({
    this.isLoading = false,
    this.emailError,
    this.isEmailButtonEnabled = false,
    this.signupEmail,
    this.canResendEmail = false,
    this.resendCountdownSeconds = 60,
    this.isTimerRunning = false,
    this.passwordError,
    this.confirmPasswordError,
    this.generalError,
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
    bool? isTimerRunning,
    String? passwordError,
    String? confirmPasswordError,
    String? generalError,
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
        isTimerRunning: isTimerRunning ?? this.isTimerRunning,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
        generalError: generalError,
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
        isTimerRunning,
        passwordError,
        confirmPasswordError,
        generalError,
        isPasswordButtonEnabled,
        passwordFieldTrigger,
      ];
}
