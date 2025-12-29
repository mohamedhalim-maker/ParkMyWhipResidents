import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_text_button.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/contact_us_text.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/step_progress_indicator.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/resident/vehicle_info_form.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/resident/vehicle_info_header.dart';

class AddVehicleInfoPage extends StatelessWidget {
  const AddVehicleInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ResidentOnboardingCubit>().backFromVehicleInfo();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: BlocBuilder<ResidentOnboardingCubit, ResidentOnboardingState>(
          builder: (context, state) {
            final cubit = context.read<ResidentOnboardingCubit>();
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
                  Visibility(
                    visible: !state.showVehicleForm,
                    child: VehicleInfoHeader(onTap: () {
                      cubit.onVehicleHeaderTapped();
                    }),
                  ),
                  Visibility(
                    visible: state.showVehicleForm,
                    child: VehicleInfoForm(
                      cubit: cubit,
                      state: state,
                    ),
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
                          cubit.backFromVehicleInfo();
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
