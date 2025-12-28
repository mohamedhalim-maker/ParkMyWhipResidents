import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_manager.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_state.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:park_my_whip_residents/src/core/services/password_recovery_manager.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({
    required this.validators,
    required this.authManager,
  }) : super(const ForgotPasswordState());

  final Validators validators;
  final AuthManager authManager;

  // Forgot password email controller
  final TextEditingController emailController = TextEditingController();

  // Reset password controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Timer for resend countdown
  Timer? _resendTimer;

  // Format countdown time to mm:ss format
  static String formatCountdownTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Forgot password field validation
  void onEmailFieldChanged() {
    emit(state.copyWith(emailError: null));
    _validateEmailForm();
  }

  void _validateEmailForm() {
    bool isValid = emailController.text.trim().isNotEmpty;
    emit(state.copyWith(isEmailButtonEnabled: isValid));
  }

  // Validate and send forgot password email
  Future<void> validateEmailForm({required BuildContext context}) async {
    final emailError = validators.emailValidator(emailController.text.trim());

    if (emailError != null) {
      emit(state.copyWith(emailError: emailError));
      return;
    }

    emit(state.copyWith(isLoading: true, emailError: null));

    final result = await authManager.resetPassword(
      email: emailController.text.trim(),
    );

    result.fold(
      (error) {
        log('🔴 Forgot password error: ${error.message}',
            name: 'ForgotPasswordCubit', level: 900);

        final errorMessage = error.message.isEmpty
            ? 'Failed to send reset link. Please try again.'
            : error.message;

        log('🔴 Displaying error to user: $errorMessage',
            name: 'ForgotPasswordCubit', level: 900);

        emit(state.copyWith(
          isLoading: false,
          emailError: errorMessage,
        ));
      },
      (_) {
        log('✅ Password reset email sent successfully',
            name: 'ForgotPasswordCubit');

        emit(state.copyWith(isLoading: false, emailError: null));

        // Start countdown timer
        _startResendCountdown();

        // Navigate to success page only if context is still valid
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(RoutesName.resetLinkSent);
        }
      },
    );
  }

  // Start countdown timer for resend
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

  // Resend password reset email
  Future<void> resendPasswordResetEmail({required BuildContext context}) async {
    emit(state.copyWith(isLoading: true, emailError: null));

    final result = await authManager.resetPassword(
      email: emailController.text.trim(),
    );

    result.fold(
      (error) {
        log('Resend password reset error: ${error.message}',
            name: 'ForgotPasswordCubit', level: 900);
        emit(state.copyWith(
          isLoading: false,
          emailError: error.message.isEmpty
              ? 'Failed to resend reset link'
              : error.message,
        ));
      },
      (_) {
        log('Password reset email resent', name: 'ForgotPasswordCubit');
        emit(state.copyWith(isLoading: false));
        // Restart countdown
        _startResendCountdown();
      },
    );
  }

  // Reset all data when navigating back from forgot password page
  void resetForgotPasswordData() {
    // Clear all controllers
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();

    // Cancel any running timer
    _resendTimer?.cancel();

    // Reset state
    emit(state.copyWith(
      emailError: null,
      passwordError: null,
      confirmPasswordError: null,
      isEmailButtonEnabled: false,
      isPasswordButtonEnabled: false,
      canResendEmail: true,
      resendCountdownSeconds: 0,
      isLoading: false,
    ));
  }

  // Navigate to forgot password page from login
  void navigateToForgotPasswordPage({
    required BuildContext context,
    required LoginCubit loginCubit,
  }) {
    // Reset login cubit data
    loginCubit.resetLoginForm();

    // Reset forgot password data before navigation
    resetForgotPasswordData();

    if (context.mounted) {
      Navigator.of(context).pushNamed(RoutesName.forgotPassword);
    }
  }

  // Navigate from reset link sent page to login
  void navigateFromResetLinkToLogin({required BuildContext context}) {
    _resendTimer?.cancel();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RoutesName.login,
        (route) => false,
      );
    }
  }

  // Reset password field validation
  void onPasswordFieldChanged() {
    emit(state.copyWith(
      passwordError: null,
      confirmPasswordError: null,
      passwordFieldTrigger: state.passwordFieldTrigger + 1,
    ));
    _validatePasswordForm();
  }

  void _validatePasswordForm() {
    bool isValid = passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty;
    emit(state.copyWith(isPasswordButtonEnabled: isValid));
  }

  // Validate and submit reset password form
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

    emit(state.copyWith(
        isLoading: true, passwordError: null, confirmPasswordError: null));

    final result = await authManager.updatePassword(
      newPassword: passwordController.text.trim(),
    );

    result.fold(
      (error) {
        log('Reset password error: ${error.message}',
            name: 'ForgotPasswordCubit', level: 900);
        emit(state.copyWith(
          isLoading: false,
          passwordError: error.message.isEmpty
              ? 'Failed to reset password'
              : error.message,
        ));
      },
      (_) async {
        log('Password updated successfully', name: 'ForgotPasswordCubit');

        // Clear recovery mode flag so user stays logged in with new password
        await PasswordRecoveryManager.setRecoveryMode(false);

        emit(state.copyWith(isLoading: false));

        // Navigate to success page
        if (context.mounted) {
          Navigator.of(context)
              .pushReplacementNamed(RoutesName.passwordResetSuccess);
        }
      },
    );
  }

  // Navigate from password reset success page to login
  void navigateFromResetSuccessToLogin({required BuildContext context}) {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RoutesName.login,
        (route) => false,
      );
    }
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
