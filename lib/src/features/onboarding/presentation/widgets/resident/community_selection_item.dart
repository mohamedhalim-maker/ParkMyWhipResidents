import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/selection_indicator.dart';

/// A selectable item for community selection list
class CommunitySelectionItem extends StatelessWidget {
  const CommunitySelectionItem({
    super.key,
    required this.communityName,
    required this.isSelected,
    required this.onTap,
  });

  final String communityName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColor.grey200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                communityName,
                style: AppTextStyles.urbanistFont16BlackSemiBold1_2,
              ),
            ),
            SelectionIndicator(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}
