import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit({
    required this.validators,
  }) : super(const SignupState());

  final Validators validators;

  // Signup email controllers
  final TextEditingController emailController = TextEditingController();

  // Set password controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Timer for resend email countdown
  Timer? _resendTimer;

  // Called when signup email field changes
  void onEmailFieldChanged() {
    emit(state.copyWith(emailError: null));
    _validateEmailForm();
  }

  // Validate signup email form and enable/disable button
  void _validateEmailForm() {
    bool isValid = emailController.text.trim().isNotEmpty;
    emit(state.copyWith(isEmailButtonEnabled: isValid));
  }

  // Validate and submit signup email form
  Future<void> validateEmailForm({required BuildContext context}) async {
    final emailError = validators.emailValidator(emailController.text.trim());

    if (emailError != null) {
      emit(state.copyWith(emailError: emailError));
      return;
    }

    // Save email to state for next step
    emit(state.copyWith(
      signupEmail: emailController.text.trim(),
      emailError: null,
    ));

    log('Signup email saved: ${state.signupEmail}', name: 'SignupCubit');

    // Navigate to verify email page
    if (context.mounted) {
      Navigator.of(context).pushNamed(RoutesName.verifyEmail);
      // Start countdown timer for resend
      _startResendCountdown();
    }
  }

  // Start countdown timer for resend verification email
  void _startResendCountdown() {
    _resendTimer?.cancel();
    emit(state.copyWith(canResendEmail: false, resendCountdownSeconds: 60));

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdownSeconds > 1) {
        emit(state.copyWith(
            resendCountdownSeconds: state.resendCountdownSeconds - 1));
      } else {
        timer.cancel();
        emit(state.copyWith(canResendEmail: true, resendCountdownSeconds: 0));
      }
    });
  }

  // Format countdown time to MM:SS format
  static String formatCountdownTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Resend verification email
  Future<void> resendVerificationEmail({required BuildContext context}) async {
    if (state.isLoading || !state.canResendEmail) return;

    try {
      emit(state.copyWith(isLoading: true, emailError: null));

      // TODO: Implement actual email sending logic here
      // await authManager.sendVerificationEmail(email: state.signupEmail!);

      log('Verification email resent to ${state.signupEmail}',
          name: 'SignupCubit');

      emit(state.copyWith(isLoading: false));

      // Restart countdown
      _startResendCountdown();
    } catch (e) {
      log('Resend verification error: $e', name: 'SignupCubit', level: 900);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        emailError: errorMessage.isEmpty
            ? 'Failed to resend verification email'
            : errorMessage,
      ));
    }
  }

  // Navigate back to email entry (when clicking "Change")
  void navigateBackToEmailEntry({required BuildContext context}) {
    _resendTimer?.cancel();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  // Navigate to login page
  void navigateToLogin({required BuildContext context}) {
    _resendTimer?.cancel();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(RoutesName.login);
    }
  }

  // Called when set password fields change
  void onPasswordFieldChanged() {
    emit(state.copyWith(
      passwordError: null,
      confirmPasswordError: null,
      passwordFieldTrigger: state.passwordFieldTrigger + 1,
    ));
    _validatePasswordForm();
  }

  // Validate set password form and enable/disable button
  void _validatePasswordForm() {
    bool isValid = passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty;
    emit(state.copyWith(isPasswordButtonEnabled: isValid));
  }

  // Validate and submit set password form
  Future<void> validatePasswordForm({required BuildContext context}) async {
    final passwordError =
        validators.passwordValidator(passwordController.text.trim());
    final confirmPasswordError = validators.conformPasswordValidator(
      passwordController.text.trim(),
      confirmPasswordController.text.trim(),
    );

    if (passwordError != null || confirmPasswordError != null) {
      emit(state.copyWith(
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
      ));
      return;
    }

    log('Password is valid and ready to send with email: ${state.signupEmail}',
        name: 'SignupCubit');

    // TODO: Send registration request with email and password
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    return super.close();
  }
}
