import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_manager.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required this.validators,
    required this.authManager,
  }) : super(const LoginState());

  final Validators validators;
  final AuthManager authManager;

  // Text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Called when login fields change
  void onFieldChanged() {
    emit(state.copyWith(
      emailError: null,
      passwordError: null,
      generalError: null,
    ));
    _validateForm();
  }

  // Validate login form and enable/disable button
  void _validateForm() {
    bool isValid = emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty;
    emit(state.copyWith(isButtonEnabled: isValid));
  }

  // Validate and submit login form
  Future<void> validateLoginForm({required BuildContext context}) async {
    final emailError = validators.emailValidator(emailController.text.trim());
    final passwordError =
        validators.loginPasswordValidator(passwordController.text.trim());

    if (emailError != null || passwordError != null) {
      emit(state.copyWith(
        emailError: emailError,
        passwordError: passwordError,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, generalError: null));

    try {
      final user = await (authManager as EmailSignInManager).signInWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        log('User logged in successfully: ${user.email}', name: 'LoginCubit');
        emit(state.copyWith(isLoading: false));

        // Navigate to dashboard on successful login
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(RoutesName.dashboard);
        }
      }
    } catch (e) {
      log('Login error: $e', name: 'LoginCubit', level: 900);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        isLoading: false,
        generalError: errorMessage.isEmpty
            ? 'An error occurred during login'
            : errorMessage,
      ));
    }
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
