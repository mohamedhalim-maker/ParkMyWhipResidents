import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';

class AlreadyHaveAccountText extends StatelessWidget {
  const AlreadyHaveAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: AuthStrings.alreadyHaveAccount,
        style: AppTextStyles.urbanistFont15Grey700Regular1_33,
        children: [
          TextSpan(
            text: AuthStrings.logIn,
            style: AppTextStyles.urbanistFont16RichRedSemiBold1_2,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
