import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';

class VehicleInfoHeader extends StatelessWidget {
  const VehicleInfoHeader({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          border: Border.all(color: AppColor.grey200, width: 1.w),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.grey400.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.car,
              size: 20.w,
              color: AppColor.grey800,
            ),
            verticalSpace(15),
            Row(
              children: [
                // Text
                Expanded(
                  child: Text(
                    OnboardingStrings.addVehicleInfo,
                    style: AppTextStyles.urbanistFont14Grey700Regular1_28,
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  size: 18.w,
                  color: AppColor.grey700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
