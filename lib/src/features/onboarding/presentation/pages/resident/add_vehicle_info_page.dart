import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_text_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/contact_us_text.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/step_progress_indicator.dart';

class AddVehicleInfoPage extends StatelessWidget {
  const AddVehicleInfoPage({super.key});

  /// Generate list of years from 1980 to current year
  List<int> _generateYearList() {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 1980 + 1, (index) => currentYear - index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ResidentOnboardingCubit>().clearVehicleData();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: BlocBuilder<ResidentOnboardingCubit, ResidentOnboardingState>(
          builder: (context, state) {
            final cubit = context.read<ResidentOnboardingCubit>();
            final yearList = _generateYearList();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(60),

                  // Step 4 label
                  Text(
                    OnboardingStrings.step4,
                    style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                  ),

                  verticalSpace(8),

                  // Page title
                  Text(
                    OnboardingStrings.addYourVehicleInfo,
                    style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                  ),

                  verticalSpace(8),

                  // Subtitle
                  Text(
                    OnboardingStrings.pleaseProvideYourVehicleDetails,
                    style: AppTextStyles.urbanistFont14Gray800Regular1_4,
                  ),

                  verticalSpace(24),

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              OnboardingStrings.vehicleYear,
                              style: AppTextStyles.urbanistFont14Gray800Regular1_4,
                            ),
                            verticalSpace(4),
                            Container(
                              height: 48.h,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColor.grey300, width: 1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  hint: Text(
                                    OnboardingStrings.selectYear,
                                    style: AppTextStyles.urbanistFont16Grey800Opacity40Regular1_3,
                                  ),
                                  value: cubit.selectedVehicleYear,
                                  icon: Icon(Icons.keyboard_arrow_down, color: AppColor.grey400),
                                  style: AppTextStyles.urbanistFont16Grey800Regular1_3,
                                  items: yearList.map((year) {
                                    return DropdownMenuItem<int>(
                                      value: year,
                                      child: Text(year.toString()),
                                    );
                                  }).toList(),
                                  onChanged: cubit.onVehicleYearSelected,
                                ),
                              ),
                            ),
                          ],
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

                  verticalSpace(8),

                  // Contact us text
                  const ContactUsText(),

                  const Spacer(),

                  // Step progress indicator (4/8 steps)
                  const StepProgressIndicator(currentStep: 4, totalSteps: 8),

                  verticalSpace(16),

                  // Back and Next buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CommonTextButton(
                        text: OnboardingStrings.back,
                        onPressed: () {
                          cubit.clearVehicleData();
                          Navigator.of(context).pop();
                        },
                        width: 110.w,
                      ),
                      CommonButton(
                        text: OnboardingStrings.next,
                        onPressed: () =>
                            cubit.onContinueAddVehicleInfo(context: context),
                        isEnabled: state.isButtonEnabled,
                        width: 110.w,
                      ),
                    ],
                  ),

                  verticalSpace(24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
