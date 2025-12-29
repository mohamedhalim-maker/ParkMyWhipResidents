import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';

/// Reusable "Have questions? Contact us" text widget
/// 
/// Displays a clickable "Contact us" link that can be used across onboarding pages
class ContactUsText extends StatelessWidget {
  const ContactUsText({super.key});

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: AppTextStyles.urbanistFont14Grey700Regular1_28,
      children: [
        TextSpan(text: OnboardingStrings.haveQuestions),
        TextSpan(
          text: OnboardingStrings.contactUs,
          style: AppTextStyles.urbanistFont14Grey700Regular1_28.copyWith(
            decoration: TextDecoration.underline,
            color: AppColor.grey800,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // TODO: Navigate to contact page or show dialog
            },
        ),
      ],
    ),
  );
}
