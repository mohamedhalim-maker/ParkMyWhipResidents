import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/auth/auth_manager.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this.validators,
    required this.authManager,
  }) : super(const AuthState());

  final Validators validators;
  final AuthManager authManager;

  // Text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  
  // Forgot password controllers
  final TextEditingController forgotPasswordEmailController = TextEditingController();
  
  // Reset password controllers
  final TextEditingController resetPasswordController = TextEditingController();
  final TextEditingController resetConfirmPasswordController = TextEditingController();
  
  // Timer for resend countdown
  Timer? _resendTimer;

  // Toggle between login and signup mode
  void toggleAuthMode() {
    emit(state.copyWith(
      isLoginMode: !state.isLoginMode,
      emailError: null,
      passwordError: null,
      confirmPasswordError: null,
      firstNameError: null,
      lastNameError: null,
      errorMessage: null,
      successMessage: null,
    ));
    _validateForm();
  }

  // Called when any field changes
  void onFieldChanged() {
    emit(state.copyWith(
      emailError: null,
      passwordError: null,
      confirmPasswordError: null,
      firstNameError: null,
      lastNameError: null,
      errorMessage: null,
      successMessage: null,
    ));
    _validateForm();
  }

  // Called when login fields change
  void onLoginFieldChanged() {
    emit(state.copyWith(
      loginEmailError: null,
      loginPasswordError: null,
      loginGeneralError: null,
    ));
    _validateLoginForm();
  }

  // Validate login form and enable/disable button
  void _validateLoginForm() {
    bool isValid = loginEmailController.text.trim().isNotEmpty && 
                   loginPasswordController.text.trim().isNotEmpty;
    emit(state.copyWith(isLoginButtonEnabled: isValid));
  }

  // Validate form and enable/disable button
  void _validateForm() {
    bool isValid = false;

    if (state.isLoginMode) {
      // Login mode validation
      isValid = emailController.text.trim().isNotEmpty && 
                passwordController.text.trim().isNotEmpty;
    } else {
      // Signup mode validation
      isValid = firstNameController.text.trim().isNotEmpty &&
                lastNameController.text.trim().isNotEmpty &&
                emailController.text.trim().isNotEmpty &&
                passwordController.text.trim().isNotEmpty &&
                confirmPasswordController.text.trim().isNotEmpty;
    }

    emit(state.copyWith(isButtonEnabled: isValid));
  }

  // Validate and submit login form
  Future<void> validateLoginForm({required BuildContext context}) async {
    final emailError = validators.emailValidator(loginEmailController.text.trim());
    final passwordError = validators.loginPasswordValidator(loginPasswordController.text.trim());

    if (emailError != null || passwordError != null) {
      emit(state.copyWith(
        loginEmailError: emailError,
        loginPasswordError: passwordError,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, loginGeneralError: null));

    try {
      final user = await (authManager as EmailSignInManager).signInWithEmail(
        context,
        loginEmailController.text.trim(),
        loginPasswordController.text.trim(),
      );

      if (user != null) {
        log('User logged in successfully: ${user.email}', name: 'AuthCubit');
        emit(state.copyWith(isLoading: false));
        
        // Navigate to dashboard on successful login
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(RoutesName.dashboard);
        }
      }
    } catch (e) {
      log('Login error: $e', name: 'AuthCubit', level: 900);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        loginGeneralError: errorMessage.isEmpty ? 'An error occurred during login' : errorMessage,
      ));
    }
  }

  // Sign in method (alternative for other pages)
  Future<void> signIn(BuildContext context) async {
    if (!_validateSignIn()) return;

    emit(state.copyWith(isLoading: true, errorMessage: null, successMessage: null));

    // TODO: Implement Supabase authentication after reconnecting
    log('Sign in validation passed - awaiting Supabase setup', name: 'AuthCubit');
    emit(state.copyWith(
      isLoading: false,
      errorMessage: 'Authentication not configured. Please connect Supabase.',
    ));
  }

  // Validate sign in fields
  bool _validateSignIn() {
    final emailError = validators.emailValidator(emailController.text.trim());
    final passwordError = validators.passwordValidator(passwordController.text.trim());

    if (emailError != null || passwordError != null) {
      emit(state.copyWith(
        emailError: emailError,
        passwordError: passwordError,
      ));
      return false;
    }
    return true;
  }

  // Format countdown time to mm:ss format
  static String formatCountdownTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Forgot password field validation
  void onForgotPasswordFieldChanged() {
    emit(state.copyWith(forgotPasswordEmailError: null));
    _validateForgotPasswordForm();
  }

  void _validateForgotPasswordForm() {
    bool isValid = forgotPasswordEmailController.text.trim().isNotEmpty;
    emit(state.copyWith(isForgotPasswordButtonEnabled: isValid));
  }

  // Validate and send forgot password email
  Future<void> validateForgotPasswordForm({required BuildContext context}) async {
    final emailError = validators.emailValidator(forgotPasswordEmailController.text.trim());

    if (emailError != null) {
      emit(state.copyWith(forgotPasswordEmailError: emailError));
      return;
    }

    emit(state.copyWith(isLoading: true, forgotPasswordEmailError: null));

    try {
      await authManager.resetPassword(
        email: forgotPasswordEmailController.text.trim(),
        context: context,
      );
      log('Password reset email sent', name: 'AuthCubit');
      emit(state.copyWith(isLoading: false));
      
      // Start countdown timer
      _startResendCountdown();
      
      // Navigate to success page
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(RoutesName.resetLinkSent);
      }
    } catch (e) {
      log('Forgot password error: $e', name: 'AuthCubit', level: 900);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        forgotPasswordEmailError: errorMessage.isEmpty ? 'Failed to send reset link' : errorMessage,
      ));
    }
  }

  // Start countdown timer for resend
  void _startResendCountdown() {
    _resendTimer?.cancel();
    emit(state.copyWith(canResendEmail: false, resendCountdownSeconds: 60));
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdownSeconds > 1) {
        emit(state.copyWith(resendCountdownSeconds: state.resendCountdownSeconds - 1));
      } else {
        timer.cancel();
        emit(state.copyWith(canResendEmail: true, resendCountdownSeconds: 0));
      }
    });
  }

  // Resend password reset email
  Future<void> resendPasswordResetEmail({required BuildContext context}) async {
    emit(state.copyWith(isLoading: true, forgotPasswordEmailError: null));

    try {
      await authManager.resetPassword(
        email: forgotPasswordEmailController.text.trim(),
        context: context,
      );
      log('Password reset email resent', name: 'AuthCubit');
      emit(state.copyWith(isLoading: false));
      
      // Restart countdown
      _startResendCountdown();
    } catch (e) {
      log('Resend password reset error: $e', name: 'AuthCubit', level: 900);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        forgotPasswordEmailError: errorMessage.isEmpty ? 'Failed to resend reset link' : errorMessage,
      ));
    }
  }

  // Navigate to forgot password page from login
  void navigateToForgotPasswordPage({required BuildContext context}) {
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
  void onResetPasswordFieldChanged() {
    emit(state.copyWith(
      resetPasswordError: null,
      resetConfirmPasswordError: null,
      resetPasswordFieldTrigger: state.resetPasswordFieldTrigger + 1,
    ));
    _validateResetPasswordForm();
  }

  void _validateResetPasswordForm() {
    bool isValid = resetPasswordController.text.trim().isNotEmpty && 
                   resetConfirmPasswordController.text.trim().isNotEmpty;
    emit(state.copyWith(isResetPasswordButtonEnabled: isValid));
  }

  // Validate and submit reset password form
  Future<void> validateResetPasswordForm({required BuildContext context}) async {
    final passwordError = validators.passwordValidator(resetPasswordController.text.trim());
    final confirmPasswordError = validators.conformPasswordValidator(
      resetPasswordController.text.trim(),
      resetConfirmPasswordController.text.trim(),
    );

    if (passwordError != null || confirmPasswordError != null) {
      emit(state.copyWith(
        resetPasswordError: passwordError,
        resetConfirmPasswordError: confirmPasswordError,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, resetPasswordError: null, resetConfirmPasswordError: null));

    try {
      await authManager.updatePassword(
        newPassword: resetPasswordController.text.trim(),
        context: context,
      );
      log('Password updated successfully', name: 'AuthCubit');
      emit(state.copyWith(isLoading: false));
      
      // Navigate to success page
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(RoutesName.passwordResetSuccess);
      }
    } catch (e) {
      log('Reset password error: $e', name: 'AuthCubit', level: 900);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        resetPasswordError: errorMessage.isEmpty ? 'Failed to reset password' : errorMessage,
      ));
    }
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
    firstNameController.dispose();
    lastNameController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    forgotPasswordEmailController.dispose();
    resetPasswordController.dispose();
    resetConfirmPasswordController.dispose();
    return super.close();
  }
}
