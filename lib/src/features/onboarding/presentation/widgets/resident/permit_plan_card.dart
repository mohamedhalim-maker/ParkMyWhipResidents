import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/permit_plan_model.dart';

/// Card widget for displaying and selecting a parking permit plan.
/// 
/// Features:
/// - Shows period (e.g., "Weekly") and price (e.g., "$60")
/// - Red border and checkmark when selected
/// - Tap to select
class PermitPlanCard extends StatelessWidget {
  final PermitPlanModel plan;
  final bool isSelected;
  final VoidCallback onTap;

  const PermitPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric( vertical: 16.h,horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.redAlerts.withValues(alpha: 0.1) :AppColor.gray100,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColor.redAlerts : AppColor.grey300,
            width:  1.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             if (isSelected) ...[
              const Spacer(),
             
            ],
            Text(
              '${plan.period} : ',
              style: isSelected
                  ? AppTextStyles.urbanistFont14Grey700Medium1_28.copyWith(color: AppColor.redAlerts)
                  : AppTextStyles.urbanistFont14Grey700Medium1_28,
            ),
            Text(
              '\$${plan.price}',
              style: isSelected
                  ? AppTextStyles.urbanistFont14Grey800Bold1.copyWith(color: AppColor.redAlerts)
                  : AppTextStyles.urbanistFont14Grey800Bold1,
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(
                Icons.check,
                color: AppColor.redAlerts,
                size: 24.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
