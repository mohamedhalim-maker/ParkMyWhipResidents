import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_text_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/contact_us_text.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/step_progress_indicator.dart';

class AddBuildingUnitPage extends StatelessWidget {
  const AddBuildingUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClaimPermitCubit>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          cubit.clearBuildingUnitData();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<ClaimPermitCubit, ClaimPermitState>(
            builder: (context, state) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(60),

                    // Step text
                    Text(
                      OnboardingStrings.step2,
                      style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                    ),

                    verticalSpace(8),

                    // Title
                    Text(
                      OnboardingStrings.addYourHostBuildingAndUnitNumber,
                      style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                    ),

                    // verticalSpace(8),

                    // // Subtitle
                    // Text(
                    //   OnboardingStrings.addBuildingUnitSubtitle,
                    //   style: AppTextStyles.urbanistFont14Grey700Regular1_28,
                    // ),

                    verticalSpace(24),

                    // Unit Number Field
                    CustomTextField(
                      title: '',
                      hintText: OnboardingStrings.unitNumberHint,
                      controller: cubit.unitNumberController,
                      validator: (_) => state.unitNumberError,
                      onChanged: (_) => cubit.onUnitNumberChanged(),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      showError: false,
                      showTitle: false,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                    ),

                    // Building Number Field
                    CustomTextField(
                      title: '',
                      hintText: OnboardingStrings.buildingNumberHint,
                      controller: cubit.buildingNumberController,
                      validator: (_) => state.buildingNumberError,
                      onChanged: (_) => cubit.onBuildingNumberChanged(),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      showError: false,
                      showTitle: false,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16.r),
                        bottomRight: Radius.circular(16.r),
                      ),
                    ),

                    verticalSpace(16),

                    // Contact us text
                    ContactUsText(),

                    Spacer(),

                    // Step progress indicator
                    StepProgressIndicator(currentStep: 2, totalSteps: 7),

                    verticalSpace(16),

                    // Back and Next buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        CommonTextButton(
                          text: OnboardingStrings.back,
                          onPressed: () {
                            cubit.clearBuildingUnitData();
                            Navigator.of(context).pop();
                          },
                          width: 110.w,
                        ),

                        // Next button
                        CommonButton(
                          text: OnboardingStrings.next,
                          onPressed: () =>
                              cubit.onContinueAddBuildingUnit(context: context),
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
      ),
    );
  }
}
