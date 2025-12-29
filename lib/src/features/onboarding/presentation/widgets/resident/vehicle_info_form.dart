import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart';

class VehicleInfoForm extends StatelessWidget {
  const VehicleInfoForm({super.key, required this.cubit, required this.state});
  final ResidentOnboardingCubit cubit;
  final ResidentOnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Vehicle info form fields go here

        // Plate Number
        CustomTextField(
          title: OnboardingStrings.plateNumber,
          hintText: OnboardingStrings.plateNumberHint,
          controller: cubit.plateNumberController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          validator: (_) => state.plateNumberError,
          onChanged: (_) => cubit.onPlateNumberChanged(),
        ),
        verticalSpace(16),

        // Vehicle Make and Model (side by side)
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CustomTextField(
                title: OnboardingStrings.vehicleMake,
                hintText: OnboardingStrings.vehicleMakeHint,
                controller: cubit.vehicleMakeController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: (_) => state.vehicleMakeError,
                onChanged: (_) => cubit.onVehicleMakeChanged(),
              ),
            ),
            horizontalSpace(12),
            Expanded(
              flex: 1,
              child: CustomTextField(
                title: OnboardingStrings.vehicleModel,
                hintText: OnboardingStrings.vehicleModelHint,
                controller: cubit.vehicleModelController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: (_) => state.vehicleModelError,
                onChanged: (_) => cubit.onVehicleModelChanged(),
              ),
            ),
          ],
        ),
        verticalSpace(16),

        // Vehicle Year and Color (side by side)
        Row(
          children: [
            // Vehicle Year Dropdown
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
              ),
            ),
          ],
        ),
      ],
    );
  }
}
