import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_state.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/widgets/resend_timer_button.dart';

/// Success page displayed after sending password reset email

class ResetLinkSentPage extends StatelessWidget {
  const ResetLinkSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        return PopScope(
          canPop: false, // Disable back button
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppColor.white,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/success.png',
                              width: 220.w,
                              height: 220.h,
                            ),
                            verticalSpace(32),
                            Text(
                              AuthStrings.resetLinkSent,
                              style:
                                  AppTextStyles.urbanistFont28Grey800SemiBold1,
                            ),
                            verticalSpace(8),
                            Text(
                              AuthStrings.resetLinkSentSubtitle,
                              style: AppTextStyles
                                  .urbanistFont15Grey700Regular1_33,
                              textAlign: TextAlign.center,
                            ),
                            if (state.emailError != null &&
                                state.emailError!.isNotEmpty) ...[
                              verticalSpace(16),
                              Text(
                                state.emailError!,
                                style: AppTextStyles
                                    .urbanistFont12Red500Regular1_5,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w)
                        .copyWith(bottom: 16.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Resend button or countdown
                        ResendTimerButton(
                          canResend: state.canResendEmail,
                          countdownSeconds: state.resendCountdownSeconds,
                          isLoading: state.isLoading,
                          onResend: () => context
                              .read<ForgotPasswordCubit>()
                              .resendPasswordResetEmail(context: context),
                          formatCountdownTime:
                              ForgotPasswordCubit.formatCountdownTime,
                        ),

                        verticalSpace(8),

                        // Go to login button
                        CommonButton(
                          text: AuthStrings.goToLogin,
                          onPressed: () => context
                              .read<ForgotPasswordCubit>()
                              .navigateFromResetLinkToLogin(context: context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
