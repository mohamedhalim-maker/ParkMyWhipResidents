import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_state.dart';

class VehicleInfoForm extends StatelessWidget {
  const VehicleInfoForm({super.key, required this.cubit, required this.state});
  final ClaimPermitCubit cubit;
  final ClaimPermitState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200, width: 1),
      ),
      child: Column(
        children: [
          // Plate Number
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  title: OnboardingStrings.plateNumber,
                  hintText: OnboardingStrings.plateNumberHint,
                  controller: cubit.plateNumberController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: (_) => state.plateNumberError,
                  onChanged: (_) => cubit.onPlateNumberChanged(),
                  fillColor: AppColor.white,
                ),
              ),
              horizontalSpace(12),
              Expanded(
                flex: 1,
                child: CustomTextField(
                  title: OnboardingStrings.vehicleYear,
                  hintText: OnboardingStrings.vehicleYearHint,
                  controller: cubit.vehicleYearController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (_) => state.vehicleYearError,
                  onChanged: (_) => cubit.onVehicleYearChanged(),
                  fillColor: AppColor.white,
                ),
              ),
            ],
          ),
          verticalSpace(16),
          // Vehicle Make and Model (side by side)
          CustomTextField(
            title: OnboardingStrings.vehicleMake,
            hintText: OnboardingStrings.vehicleMakeHint,
            controller: cubit.vehicleMakeController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (_) => state.vehicleMakeError,
            onChanged: (_) => cubit.onVehicleMakeChanged(),
            fillColor: AppColor.white,
          ),
          verticalSpace(16),
          // Vehicle Year and Color (side by side)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  title: OnboardingStrings.vehicleModel,
                  hintText: OnboardingStrings.vehicleModelHint,
                  controller: cubit.vehicleModelController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: (_) => state.vehicleModelError,
                  onChanged: (_) => cubit.onVehicleModelChanged(),
                  fillColor: AppColor.white,
                ),
              ),

              horizontalSpace(12),
              // Vehicle Color
              Expanded(
                flex: 1,
                child: CustomTextField(
                  title: OnboardingStrings.vehicleColor,
                  hintText: OnboardingStrings.vehicleColorHint,
                  controller: cubit.vehicleColorController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  validator: (_) => state.vehicleColorError,
                  onChanged: (_) => cubit.onVehicleColorChanged(),
                  fillColor: AppColor.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
