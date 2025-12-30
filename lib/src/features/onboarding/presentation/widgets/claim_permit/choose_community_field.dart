import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/claim_permit/community_selection_bottom_sheet.dart';

/// A clickable field that allows users to choose their community
class ChooseCommunityField extends StatelessWidget {
  const ChooseCommunityField({
    super.key,
    this.selectedCommunity,
  });

  final String? selectedCommunity;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCommunitySelectionBottomSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          border: Border.all(color: AppColor.grey200, width: 1.w),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.grey400.withValues(alpha: 0.08),
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Location icon
            Icon(
              AppIcons.locationIcon,
              size: 16.w,
              color: AppColor.grey700,
            ),

            horizontalSpace(12),

            // Text
            Expanded(
              child: Text(
                selectedCommunity ?? OnboardingStrings.chooseYourCommunity,
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
      ),
    );
  }
}
