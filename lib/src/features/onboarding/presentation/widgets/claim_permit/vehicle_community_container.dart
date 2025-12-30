import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/onboarding_data_model.dart';

class VehicleCommunityContainer extends StatelessWidget {
  final OnboardingDataModel data;

  const VehicleCommunityContainer({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title: Plate Number
          Text(
            OnboardingStrings.plateNumber,
            style: AppTextStyles.urbanistFont12Grey800Regular1_64,
          ),

          verticalSpace(4),

          // Plate number and vehicle info
          Row(
            children: [
              // Plate number box
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.grey700, width: 0.3.w),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  data.plateNumber ?? OnboardingStrings.notAvailable,
                  style: AppTextStyles.urbanistFont16Grey800SemiBold1_2,
                ),
              ),

              horizontalSpace(12),

              // Vehicle make, model, year, color
              Expanded(
                child: Text(
                  '${data.vehicleMake ?? ''}-${data.vehicleModel ?? ''} ${data.vehicleYear ?? ''}- ${data.vehicleColor ?? ''}',
                  style: AppTextStyles.urbanistFont14Grey700Medium1_25,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          verticalSpace(12),

          // Section title: Community and Unit Number
          Text(
            OnboardingStrings.communityAndUnitNumber,
            style: AppTextStyles.urbanistFont12Grey800Regular1_64,
          ),

          verticalSpace(4),

          // Community, Building, Unit info
          Text(
            '${data.selectedCommunity ?? ''} - ${OnboardingStrings.building}${data.buildingNumber ?? ''} ${OnboardingStrings.unit}${data.unitNumber ?? ''}',
            style: AppTextStyles.urbanistFont12Grey700SemiBold1_2,
          ),
        ],
      ),
    );
  }
}
