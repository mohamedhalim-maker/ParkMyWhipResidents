import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_text_button.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/contact_us_text.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/step_progress_indicator.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/resident/image_upload_widget.dart';

class UploadVehicleRegistrationPage extends StatelessWidget {
  const UploadVehicleRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ResidentOnboardingCubit>().clearRegistrationData();
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

                  // Page title
                  Text(
                    OnboardingStrings.uploadVehicleRegistration,
                    style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                  ),

                  verticalSpace(24),

                  // Registration upload widget
                  ImageUploadWidget(
                    image: state.registrationImage,
                    fileName: state.registrationFileName,
                    isLoading: state.isLoadingImage,
                    onTap: () => cubit.handleRegistrationUpload(context),
                    onRemove: () => cubit.removeRegistrationImage(),
                  ),

                  verticalSpace(8),

                  // Max file size text
                  Text(
                    OnboardingStrings.maxFileSize,
                    style: AppTextStyles.urbanistFont14Gray800Regular1_4
                        .copyWith(color: AppColor.gray30),
                  ),

                  verticalSpace(8),

                  // Contact us text
                  const ContactUsText(),

                  const Spacer(),

                  // Step progress indicator (6/8 steps)
                  const StepProgressIndicator(currentStep: 6, totalSteps: 8),

                  verticalSpace(16),

                  // Back and Next buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CommonTextButton(
                        text: OnboardingStrings.back,
                        onPressed: () => Navigator.of(context).pop(),
                        width: 110.w,
                      ),
                      CommonButton(
                        text: OnboardingStrings.next,
                        onPressed: () =>
                            cubit.onContinueUploadRegistration(context: context),
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
