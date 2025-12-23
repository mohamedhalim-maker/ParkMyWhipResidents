import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_state.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/widgets/otp_widget.dart';

class EnterOtpCodePage extends StatelessWidget {
  const EnterOtpCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: BlocBuilder<SignupCubit, SignupState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(50),
                    Text(
                      AuthStrings.otpTitle,
                      style: AppTextStyles.urbanistFont34Grey800SemiBold1_2,
                    ),
                    verticalSpace(8),
                    Text(
                      AuthStrings.otpSubtitle,
                      style: AppTextStyles.urbanistFont15LightGrayRegular1_33,
                    ),
                    verticalSpace(24),
                    OtpWidget(
                      controller: context.read<SignupCubit>().otpController,
                      errorMessage: state.otpError,
                      onChanged: () {
                        context.read<SignupCubit>().onOtpFieldChanged();
                      },
                    ),
                    const Spacer(),
                    // Resend button or countdown
                    Center(
                      child: state.canResendOtp
                          ? TextButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => context
                                      .read<SignupCubit>()
                                      .resendOtp(context: context),
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
                          : Text(
                              '${AuthStrings.resendIn} ${SignupCubit.formatCountdownTime(state.otpResendCountdownSeconds)}',
                              style: AppTextStyles
                                  .urbanistFont16RichRedSemiBold1_2,
                            ),
                    ),
                    verticalSpace(12),
                    CommonButton(
                      text: state.isLoading
                          ? 'Verifying...'
                          : AuthStrings.continueText,
                      onPressed: () {
                        context.read<SignupCubit>().verifyOtp(context: context);
                      },
                      isEnabled: state.isOtpButtonEnabled && !state.isLoading,
                    ),
                    verticalSpace(16),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
