import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_state.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/widgets/password_validation_rules.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<ForgotPasswordCubit>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
            buildWhen: (previous, current) =>
                previous.passwordError != current.passwordError ||
                previous.confirmPasswordError != current.confirmPasswordError ||
                previous.isPasswordButtonEnabled !=
                    current.isPasswordButtonEnabled ||
                previous.isLoading != current.isLoading ||
                previous.passwordFieldTrigger != current.passwordFieldTrigger,
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(50),
                  Text(
                    AuthStrings.resetYourPassword,
                    style: AppTextStyles.urbanistFont34Grey800SemiBold1_2,
                  ),
                  verticalSpace(24),
                  CustomTextField(
                    title: AuthStrings.passwordLabel,
                    hintText: '',
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    controller: cubit.passwordController,
                    validator: (_) => state.passwordError,
                    onChanged: (_) => cubit.onPasswordFieldChanged(),
                    isPassword: true,
                  ),
                  verticalSpace(20),
                  CustomTextField(
                    title: AuthStrings.confirmPasswordLabel,
                    hintText: '',
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    controller: cubit.confirmPasswordController,
                    validator: (_) => state.confirmPasswordError,
                    onChanged: (_) => cubit.onPasswordFieldChanged(),
                    isPassword: true,
                  ),
                  verticalSpace(24),
                  PasswordValidationRules(
                    password: cubit.passwordController.text,
                  ),
                  Spacer(),
                  CommonButton(
                    text: state.isLoading
                        ? 'Resetting...'
                        : AuthStrings.continueText,
                    onPressed: () =>
                        cubit.validatePasswordForm(context: context),
                    isEnabled:
                        state.isPasswordButtonEnabled && !state.isLoading,
                  ),
                  verticalSpace(16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
