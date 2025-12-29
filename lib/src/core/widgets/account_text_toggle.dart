import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';

/// Reusable widget for account-related text with action link
/// Example: "Already have an account? Log in" or "Don't have an account? Sign up"
class AccountTextToggle extends StatelessWidget {
  const AccountTextToggle({
    super.key,
    required this.normalText,
    required this.actionText,
    required this.onTap,
    this.color,
    this.alignment = Alignment.center,
  });

  final String normalText;
  final String actionText;
  final VoidCallback onTap;
  final Color? color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: RichText(
        text: TextSpan(
          text: normalText,
          style: color != null
              ? AppTextStyles.urbanistFont15Grey700Regular1_33.copyWith(color: color)
              : AppTextStyles.urbanistFont15Grey700Regular1_33,
          children: [
            TextSpan(
              text: actionText,
              style: color != null
                  ? AppTextStyles.urbanistFont15Grey700SemiBold1_33.copyWith(color: color)
                  : AppTextStyles.urbanistFont15Grey700SemiBold1_33,
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      ),
    );
  }
}
