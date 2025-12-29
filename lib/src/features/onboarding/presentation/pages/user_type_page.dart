import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/general/general_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/general/general_onboarding_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/contact_us_text.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/selection_card.dart';

class UserTypePage extends StatelessWidget {
  const UserTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<GeneralOnboardingCubit, GeneralOnboardingState>(
        builder: (context, state) {
          final cubit = context.read<GeneralOnboardingCubit>();
          
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                verticalSpace(12),

                // Title
                Text(
                  OnboardingStrings.howWouldYouLikeToGetStarted,
                  style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                ),

                verticalSpace(8),

                // Subtitle
                Text(
                  OnboardingStrings.userTypeSubtitle,
                  style: AppTextStyles.urbanistFont14Grey700Regular1_28,
                ),

                verticalSpace(24),

                // Resident option
                SelectionCard(
                  icon: AppIcons.homeIcon,
                  title: OnboardingStrings.resident,
                  description: OnboardingStrings.residentDescription,
                  isSelected: state.selectedUserType == 'resident',
                  onTap: () => cubit.onUserTypeChanged('resident'),
                ),

                verticalSpace(16),

                // Visitor option
                SelectionCard(
                  icon: AppIcons.stickMan,
                  title: OnboardingStrings.visitor,
                  description: OnboardingStrings.visitorDescription,
                  isSelected: state.selectedUserType == 'visitor',
                  onTap: () => cubit.onUserTypeChanged('visitor'),
                ),

              
                verticalSpace(16),

                // Contact us text
                ContactUsText(),

                Spacer(),

                // Continue Button
                CommonButton(
                  text: OnboardingStrings.continueButton,
                  onPressed: () => cubit.onContinueUserType(context: context),
                  isEnabled: state.isButtonEnabled,
                ),

                verticalSpace(24),
              ],
            ),
          );
        },
      ),
    );
  }
}

