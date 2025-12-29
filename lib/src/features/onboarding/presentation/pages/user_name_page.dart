import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/account_text_toggle.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/terms_checkbox.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/general/general_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/general/general_onboarding_state.dart';

class UserNamePage extends StatelessWidget {
  const UserNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        onBackPress: () {}, // Empty for now
      ),
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
                  OnboardingStrings.whatsYourName,
                  style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                ),

                verticalSpace(24),

                // First name field
                CustomTextField(
                  title: OnboardingStrings.firstName,
                  hintText: OnboardingStrings.firstNameHint,
                  controller: cubit.firstNameController,
                  validator: (_) => state.firstNameError,
                  onChanged: (_) => cubit.onFirstNameChanged(),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),

                verticalSpace(16),

                // Last name field
                CustomTextField(
                  title: OnboardingStrings.lastName,
                  hintText: OnboardingStrings.lastNameHint,
                  controller: cubit.lastNameController,
                  validator: (_) => state.lastNameError,
                  onChanged: (_) => cubit.onLastNameChanged(),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.done,
                ),

                verticalSpace(20),

                // Terms & Conditions Checkbox
                TermsCheckbox(
                  text: OnboardingStrings.termsCheckboxText,
                  value: cubit.termsAccepted,
                  onChanged: (value) => cubit.onTermsChanged(value ?? false),
                ),
                Spacer(),
                // Bottom section with "Already have account" and Continue button
                AccountTextToggle(
                  normalText: OnboardingStrings.alreadyHaveAccount,
                  actionText: OnboardingStrings.logIn,
                  onTap: () {}, // Will navigate to login
                ),

                verticalSpace(16),

                // Continue Button
                CommonButton(
                  text: OnboardingStrings.continueButton,
                  onPressed: () => cubit.onContinuePersonalInfo(context: context),
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
