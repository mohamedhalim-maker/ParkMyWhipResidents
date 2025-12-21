import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? generalError;
  final bool isButtonEnabled;

  const LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.generalError,
    this.isButtonEnabled = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? emailError,
    String? passwordError,
    String? generalError,
    bool? isButtonEnabled,
  }) =>
      LoginState(
        isLoading: isLoading ?? this.isLoading,
        emailError: emailError,
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
