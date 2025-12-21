import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_state.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/widgets/password_validation_rules.dart';

class SetPasswordPage extends StatelessWidget {
  const SetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<SignupCubit>();
    return Scaffold(
      appBar: CommonAppBar(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: BlocBuilder<SignupCubit, SignupState>(
            buildWhen: (previous, current) =>
                previous.passwordError != current.passwordError ||
                previous.confirmPasswordError != current.confirmPasswordError ||
                previous.generalError != current.generalError ||
                previous.isLoading != current.isLoading ||
                previous.isPasswordButtonEnabled !=
                    current.isPasswordButtonEnabled ||
                previous.passwordFieldTrigger != current.passwordFieldTrigger,
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(10),
                  Text(
                    AuthStrings.setYourPassword,
                    style: AppTextStyles.urbanistFont34Grey800SemiBold1_2,
                  ),
                  verticalSpace(24),
                  CustomTextField(
                    title: AuthStrings.passwordLabelShort,
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
                  if (state.generalError != null) ...[
                    verticalSpace(16),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              state.generalError!,
                              style: AppTextStyles.urbanistFont14Gray800Regular1_4
                                  .copyWith(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  verticalSpace(24),
                  PasswordValidationRules(
                    password: cubit.passwordController.text,
                  ),
                  const Spacer(),
                  CommonButton(
                    text: AuthStrings.continueText,
                    onPressed: () =>
                        cubit.validatePasswordForm(context: context),
                    isEnabled: state.isPasswordButtonEnabled && !state.isLoading,
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
