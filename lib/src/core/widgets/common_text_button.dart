import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';

/// A common text button widget used across the app
class CommonTextButton extends StatelessWidget {
  const CommonTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.isEnabled = true,
  });

  final String text;
  final VoidCallback onPressed;
  final double width;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48.h,
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: isEnabled
              ? AppTextStyles.urbanistFont16Grey800SemiBold1_2
              : AppTextStyles.urbanistFont16Grey800SemiBold1_2.copyWith(
                  color: AppColor.grey400,
                ),
        ),
      ),
    );
  }
}
