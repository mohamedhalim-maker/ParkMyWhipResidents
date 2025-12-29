import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/selection_indicator.dart';

/// Reusable selection card widget for onboarding options
/// 
/// Shows an icon, title, and description with a selectable state
/// indicated by a radio button and bold border when selected
class SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? AppColor.grey800 : AppColor.grey300,
          width: isSelected ? 1.5.w : 1.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Icon(
            icon,
            size: 32.sp,
            color: AppColor.grey800,
          ),
          
          horizontalSpace(16),
          
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.urbanistFont18Grey800SemiBold1_2,
                ),
                verticalSpace(4),
                Text(
                  description,
                  style: AppTextStyles.urbanistFont14Grey700Regular1_28,
                ),
              ],
            ),
          ),
          
          horizontalSpace(16),
          
          // Selection indicator (radio button)
          SelectionIndicator(isSelected: isSelected),
        ],
      ),
    ),
  );
}
