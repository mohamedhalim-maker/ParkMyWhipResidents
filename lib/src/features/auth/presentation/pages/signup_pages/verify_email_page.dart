import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_state.dart';

/// Email verification page displayed after user enters email during signup
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupCubit, SignupState>(
      builder: (context, state) {
        if (!state.isTimerRunning && state.resendCountdownSeconds == 60) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<SignupCubit>().startResendCountdown();
          });
        }

        return Scaffold(
          appBar: CommonAppBar(),
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  verticalSpace(16),
                  Text(
                    AuthStrings.verifyYourEmail,
                    style: AppTextStyles.urbanistFont34Grey800SemiBold1_2,
                  ),
                  verticalSpace(12),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.urbanistFont15Grey700Regular1_33,
                      children: [
                        TextSpan(text: AuthStrings.verificationEmailSent),
                        TextSpan(
                          text: ' ${state.signupEmail ?? ''} ',
                          style:
                              AppTextStyles.urbanistFont15Grey700SemiBold1_33,
                        ),
                        TextSpan(text: AuthStrings.unlessAlreadyHaveAccount),
                      ],
                    ),
                  ),
                  verticalSpace(16),
                  Row(
                    children: [
                      Text(
                        state.signupEmail ?? '',
                        style: AppTextStyles.urbanistFont16Grey800Regular1_3,
                      ),
                      horizontalSpace(8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context
                            .read<SignupCubit>()
                            .navigateBackToEmailEntry(context: context),
                        child: Text(
                          AuthStrings.change,
                          style: AppTextStyles.urbanistFont16RichRedSemiBold1_2,
                        ),
                      ),
                    ],
                  ),
                  if (state.emailError != null &&
                      state.emailError!.isNotEmpty) ...[
                    verticalSpace(16),
                    Text(
                      state.emailError!,
                      style: AppTextStyles.urbanistFont12Red500Regular1_5,
                    ),
                  ],
                  Spacer(),
                  Center(
                    child: Text(
                      SignupCubit.formatCountdownTime(
                          state.resendCountdownSeconds),
                      style: AppTextStyles.urbanistFont16RichRedSemiBold1_2,
                    ),
                  ),
                  verticalSpace(16),
                  CommonButton(
                    text: AuthStrings.resend,
                    isEnabled: state.canResendEmail && !state.isLoading,
                    onPressed: () => context
                        .read<SignupCubit>()
                        .resendVerificationEmail(context: context),
                  ),
                  verticalSpace(16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
