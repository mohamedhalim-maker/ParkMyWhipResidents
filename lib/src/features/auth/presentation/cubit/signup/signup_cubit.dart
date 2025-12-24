import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/app_config.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_manager.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_state.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit({
    required this.validators,
    required this.authManager,
  }) : super(const SignupState());

  final Validators validators;
  final AuthManager authManager;

  // Signup email controllers
  final TextEditingController emailController = TextEditingController();

  // Set password controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // OTP code controller
  final TextEditingController otpController = TextEditingController();

  // Timer for resend email countdown
  Timer? _resendTimer;

  // Timer for resend OTP countdown
  Timer? _otpResendTimer;

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
    final email = emailController.text.trim();
    final emailError = validators.emailValidator(email);

    if (emailError != null) {
      emit(state.copyWith(emailError: emailError));
      return;
    }

    // Show loading state
    emit(state.copyWith(isLoading: true, emailError: null));

    try {
      // Check if user exists and grant app access if needed
      AppLogger.auth('Checking user status for email: $email, appId: ${AppConfig.appId}');

      final result = await SupabaseConfig.client.rpc(
        'check_user_and_grant_app_access',
        params: {
          'user_email': email,
          'p_app_id': AppConfig.appId,
        },
      );

      AppLogger.auth('RPC result: $result (type: ${result.runtimeType})');

      final data = Map<String, dynamic>.from(result as Map);
      final status = data['status'] as String;

      AppLogger.auth('User check result - Status: $status');

      if (status == 'exists_this_app') {
        AppLogger.auth('User already exists for THIS app - showing error');
        // User already registered for this app
        emit(state.copyWith(
          isLoading: false,
          emailError: 'This email is already registered. Please sign in.',
        ));
        return;
      }

      if (status == 'granted_access') {
        AppLogger.auth('Cross-app user detected. Redirecting to login.');

        emit(state.copyWith(isLoading: false));

        // Prefill login cubit with email and error message
        getIt<LoginCubit>().prefillForCrossAppSignup(
          email: email,
          errorMessage: 'This account exists. Please sign in to access this app.',
        );

        // Navigate to login page
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(RoutesName.login);
        }
        return;
      }

      // status == 'new_user' - Continue with normal signup flow
      AppLogger.auth('New user. Proceeding to password page.');
      emit(state.copyWith(
        isLoading: false,
        signupEmail: email,
        emailError: null,
      ));

      // Navigate to set password page
      if (context.mounted) {
        Navigator.of(context).pushNamed(RoutesName.setPassword);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking user status', error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        isLoading: false,
        emailError: 'Failed to verify email. Please try again.',
      ));
    }
  }

  // Start countdown timer for resend verification email
  void startResendCountdown() {
    _resendTimer?.cancel();
    emit(state.copyWith(
      canResendEmail: false,
      resendCountdownSeconds: 60,
      isTimerRunning: true,
    ));

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdownSeconds > 1) {
        emit(state.copyWith(
            resendCountdownSeconds: state.resendCountdownSeconds - 1));
      } else {
        timer.cancel();
        emit(state.copyWith(
          canResendEmail: true,
          resendCountdownSeconds: 0,
          isTimerRunning: false,
        ));
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

      AppLogger.auth('Resending verification email to ${state.signupEmail}');

      await (authManager as EmailSignInManager)
          .resendVerificationEmail(email: state.signupEmail!);

      AppLogger.auth('Verification email resent successfully');

      emit(state.copyWith(isLoading: false));

      // Restart countdown
      startResendCountdown();
    } catch (e) {
      AppLogger.error('Resend verification error', error: e);
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

  /// Resets all signup data after successful registration
  /// Called after OTP verification to clear sensitive data and timers
  void resetAllData() {
    // Cancel all timers
    _resendTimer?.cancel();
    _otpResendTimer?.cancel();

    // Clear all controllers
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    otpController.clear();

    // Reset state to initial
    emit(const SignupState());

    AppLogger.auth('Signup data reset after successful registration');
  }

  // Called when set password fields change
  void onPasswordFieldChanged() {
    emit(state.copyWith(
      passwordError: null,
      confirmPasswordError: null,
      generalError: null,
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

    // Call auth manager to create account (Supabase auto-sends OTP)
    try {
      emit(state.copyWith(isLoading: true, generalError: null));

      AppLogger.auth('Creating account for: ${state.signupEmail}');

      await (authManager as EmailSignInManager).createAccountWithEmail(
        state.signupEmail!,
        passwordController.text.trim(),
      );

      AppLogger.auth('Account created successfully. OTP sent automatically.');

      emit(state.copyWith(isLoading: false));

      // Navigate to OTP code page
      if (context.mounted) {
        Navigator.of(context).pushNamed(RoutesName.enterOtpCode);
        // Start OTP resend countdown
        startOtpResendCountdown();

        // Clear sensitive data after navigation
        emailController.clear();
        passwordController.clear();
        emit(state.copyWith(generalError: null));
      }
    } catch (e) {
      AppLogger.error('Error creating account', error: e);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        generalError: errorMessage.isEmpty
            ? 'Failed to create account. Please try again.'
            : errorMessage,
      ));
    }
  }

  // =========== OTP Verification Methods ===========

  // Called when OTP field changes
  void onOtpFieldChanged() {
    final text = otpController.text.trim();
    emit(state.copyWith(
      otpCode: text,
      otpError: null,
      isOtpButtonEnabled: text.length == 6,
    ));
  }

  // Start countdown timer for resend OTP
  void startOtpResendCountdown() {
    _otpResendTimer?.cancel();
    emit(state.copyWith(
      canResendOtp: false,
      otpResendCountdownSeconds: 60,
    ));

    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.otpResendCountdownSeconds > 1) {
        emit(state.copyWith(
            otpResendCountdownSeconds: state.otpResendCountdownSeconds - 1));
      } else {
        timer.cancel();
        emit(state.copyWith(
          canResendOtp: true,
          otpResendCountdownSeconds: 0,
        ));
      }
    });
  }

  // Resend OTP code
  Future<void> resendOtp({required BuildContext context}) async {
    if (state.isLoading || !state.canResendOtp) return;

    try {
      emit(state.copyWith(isLoading: true, otpError: null));

      AppLogger.auth('Resending OTP to ${state.signupEmail}');

      await (authManager as EmailSignInManager)
          .resendVerificationEmail(email: state.signupEmail!);

      AppLogger.auth('OTP resent successfully');

      emit(state.copyWith(isLoading: false));

      // Restart countdown
      startOtpResendCountdown();
    } catch (e) {
      AppLogger.error('Resend OTP error', error: e);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        otpError: errorMessage.isEmpty ? 'Failed to resend OTP' : errorMessage,
      ));
    }
  }

  // Verify OTP code and navigate to dashboard on success
  Future<void> verifyOtp({required BuildContext context}) async {
    if (state.isLoading || state.otpCode.length != 6) return;

    try {
      emit(state.copyWith(isLoading: true, otpError: null));

      AppLogger.auth('Verifying OTP for ${state.signupEmail}');

      final user = await (authManager as EmailSignInManager).verifyOtpWithEmail(
        email: state.signupEmail!,
        otpCode: state.otpCode,
      );

      if (user != null) {
        AppLogger.auth('OTP verified successfully. User logged in.');

        emit(state.copyWith(
          isLoading: false,
          isOtpVerificationSuccess: true,
        ));

        // Navigate to dashboard
        if (context.mounted) {
          AppLogger.navigation(
              'Navigating to dashboard after OTP verification');
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesName.dashboard,
            (route) => false,
          );

          // Reset all signup data after successful navigation
          resetAllData();
        }
      } else {
        emit(state.copyWith(
          isLoading: false,
          otpError: 'Verification failed. Please try again.',
        ));
      }
    } catch (e) {
      AppLogger.error('OTP verification error', error: e);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        otpError: errorMessage.isEmpty
            ? 'Invalid OTP code. Please try again.'
            : errorMessage,
      ));
    }
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    _otpResendTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    return super.close();
  }
}
