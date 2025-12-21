import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_state.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        verticalSpace(24),
                        Text(
                          AuthStrings.confirmYourEmail,
                          style: AppTextStyles.urbanistFont34Grey800SemiBold1_2,
                        ),
                        verticalSpace(8),
                        Text(
                          AuthStrings.resetPasswordSubtitle,
                          style:
                              AppTextStyles.urbanistFont15LightGrayRegular1_33,
                        ),
                        verticalSpace(24),
                        CustomTextField(
                          title: AuthStrings.emailLabel,
                          hintText: AuthStrings.emailHint,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          controller:
                              getIt<ForgotPasswordCubit>().emailController,
                          validator: (_) => state.emailError,
                          onChanged: (_) => getIt<ForgotPasswordCubit>()
                              .onEmailFieldChanged(),
                        ),
                        Spacer(),
                        CommonButton(
                          text: state.isLoading
                              ? 'Sending...'
                              : AuthStrings.continueText,
                          onPressed: () => getIt<ForgotPasswordCubit>()
                              .validateEmailForm(context: context),
                          isEnabled:
                              state.isEmailButtonEnabled && !state.isLoading,
                        ),
                        verticalSpace(16),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
