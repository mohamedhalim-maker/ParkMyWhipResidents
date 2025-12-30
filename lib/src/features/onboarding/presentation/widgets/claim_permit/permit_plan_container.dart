import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/onboarding_data_model.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/user_type.dart';

class PermitPlanContainer extends StatelessWidget {
  final OnboardingDataModel data;

  const PermitPlanContainer({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Permit details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permit plan type
                Text(
                  '${OnboardingStrings.residentPermit}${data.selectedPermitPlan?.period ?? ''}',
                  style: AppTextStyles.urbanistFont12Grey800Regular1_64,
                ),

                verticalSpace(2),

                // Expiration date
                RichText(
                  text: TextSpan(
                    text: OnboardingStrings.expiresIn,
                    style: AppTextStyles.urbanistFont10Grey700Regular1_3,
                    children: [
                      TextSpan(
                        text: data.formattedExpirationDate ??
                            OnboardingStrings.notAvailable,
                        style: AppTextStyles.urbanistFont10Grey800SemiBold1_54,
                      ),
                    ],
                  ),
                ),

                verticalSpace(2),

                // Cost
                RichText(
                  text: TextSpan(
                    text: OnboardingStrings.cost,
                    style: AppTextStyles.urbanistFont12Grey800Regular1_64,
                    children: [
                      TextSpan(
                        text: '\$${data.selectedPermitPlan?.price ?? 0}',
                        style: AppTextStyles.urbanistFont12BlackBold1_2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right side: User type badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColor.grey700,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              data.userType?.displayName ?? OnboardingStrings.resident,
              style: AppTextStyles.urbanistFont12RedDarkSemiBold1.copyWith(
                color: AppColor.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
