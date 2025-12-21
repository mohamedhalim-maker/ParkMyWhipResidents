import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/auth_cubit.dart';

import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/auth_state.dart'
    as auth_state;

/// Success page displayed after sending password reset email

class ResetLinkSentPage extends StatelessWidget {
  const ResetLinkSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, auth_state.AuthState>(
      builder: (context, state) {
        return Scaffold(
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
                            'assets/images/towing_confirmed.png',
                            width: 220.w,
                            height: 220.h,
                          ),
                          verticalSpace(32),
                          Text(
                            AuthStrings.resetLinkSent,
                            style: AppTextStyles.urbanistFont28Grey800SemiBold1,
                          ),
                          verticalSpace(8),
                          Text(
                            AuthStrings.resetLinkSentSubtitle,
                            style:
                                AppTextStyles.urbanistFont15Grey700Regular1_33,
                            textAlign: TextAlign.center,
                          ),
                          if (state.forgotPasswordEmailError != null &&
                              state.forgotPasswordEmailError!.isNotEmpty) ...[
                            verticalSpace(16),
                            Text(
                              state.forgotPasswordEmailError!,
                              style:
                                  AppTextStyles.urbanistFont12Red500Regular1_5,
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

                      if (state.canResendEmail)
                        TextButton(
                          onPressed: state.isLoading
                              ? null
                              : () => context
                                  .read<AuthCubit>()
                                  .resendPasswordResetEmail(context: context),
                          child: state.isLoading
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColor.richRed,
                                  ),
                                )
                              : Text(
                                  AuthStrings.resend,
                                  style: AppTextStyles
                                      .urbanistFont16RichRedSemiBold1_2,
                                ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            '${AuthStrings.resendIn} ${AuthCubit.formatCountdownTime(state.resendCountdownSeconds)}',
                            style:
                                AppTextStyles.urbanistFont16RichRedSemiBold1_2,
                          ),
                        ),

                      verticalSpace(8),

                      // Go to login button

                      CommonButton(
                        text: AuthStrings.goToLogin,
                        onPressed: () => context
                            .read<AuthCubit>()
                            .navigateFromResetLinkToLogin(context: context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
