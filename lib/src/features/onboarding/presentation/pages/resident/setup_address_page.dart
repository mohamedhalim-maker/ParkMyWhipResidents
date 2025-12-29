import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/contact_us_text.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/step_progress_indicator.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/resident/choose_community_field.dart';

class SetupAddressPage extends StatelessWidget {
  const SetupAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<ResidentOnboardingCubit, ResidentOnboardingState>(
            builder: (context, state) {
              final cubit = context.read<ResidentOnboardingCubit>();

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(60),

                    // Step text
                    Text(
                      OnboardingStrings.step1,
                      style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                    ),

                    verticalSpace(8),

                    // Title
                    Text(
                      OnboardingStrings.letsSetupYourAddress,
                      style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                    ),

                    verticalSpace(8),

                    // Subtitle
                    Text(
                      OnboardingStrings.setupAddressSubtitle,
                      style: AppTextStyles.urbanistFont14Grey700Regular1_28,
                    ),

                    verticalSpace(24),

                    // Choose community field
                    ChooseCommunityField(
                      selectedCommunity: state.selectedCommunity,
                    ),

                    verticalSpace(16),

                    // Contact us text
                    ContactUsText(),

                    Spacer(),

                    // Step progress indicator
                    StepProgressIndicator(currentStep: 1, totalSteps: 7),

                    verticalSpace(16),

                    // Next Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: CommonButton(
                        text: OnboardingStrings.next,
                        onPressed: () =>
                            cubit.onContinueSetupAddress(context: context),
                        isEnabled: state.isButtonEnabled,
                        width: 110.w,
                      ),
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
