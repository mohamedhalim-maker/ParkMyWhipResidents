import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';

/// Reusable widget that displays either a resend button or countdown timer
/// Used in email verification and password reset flows
class ResendTimerButton extends StatelessWidget {
  final bool canResend;
  final int countdownSeconds;
  final bool isLoading;
  final VoidCallback onResend;
  final String Function(int) formatCountdownTime;

  const ResendTimerButton({
    super.key,
    required this.canResend,
    required this.countdownSeconds,
    required this.isLoading,
    required this.onResend,
    required this.formatCountdownTime,
  });

  @override
  Widget build(BuildContext context) {
    if (canResend) {
      return TextButton(
        onPressed: isLoading ? null : onResend,
        child: isLoading
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
                style: AppTextStyles.urbanistFont16RichRedSemiBold1_2,
              ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          '${AuthStrings.resendIn} ${formatCountdownTime(countdownSeconds)}',
          style: AppTextStyles.urbanistFont16RichRedSemiBold1_2,
        ),
      );
    }
  }
}
