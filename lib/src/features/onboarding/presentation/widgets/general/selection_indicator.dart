import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';

/// Radio button style selection indicator
/// 
/// Displays a circular indicator that shows selected/unselected state
/// Can be reused across multiple selection widgets in onboarding flow
class SelectionIndicator extends StatelessWidget {
  final bool isSelected;

  const SelectionIndicator({
    super.key,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 20.w,
    height: 20.h,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isSelected ? AppColor.grey800 : AppColor.grey300,
      border: Border.all(
        color: isSelected ? AppColor.grey800 : AppColor.grey300,
        width: 2.w,
      ),
    ),
    child: isSelected
        ? Center(
            child: Container(
              width: 10.w,
              height: 10.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          )
        : null,
  );
}
