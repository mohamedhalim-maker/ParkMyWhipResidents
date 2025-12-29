import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';

/// A horizontal step progress indicator showing 8 steps
/// with the first step highlighted
class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    this.currentStep = 1,
    this.totalSteps = 8,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        totalSteps,
        (index) {
          final isActive = index < currentStep;
          return Expanded(
            child: Container(
              height: 4.h,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8.w : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColor.redAlerts : AppColor.redAlerts.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          );
        },
      ),
    );
  }
}
