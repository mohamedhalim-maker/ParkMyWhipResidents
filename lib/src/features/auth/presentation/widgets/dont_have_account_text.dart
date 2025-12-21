import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';

class DontHaveAccountText extends StatelessWidget {
  const DontHaveAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: RichText(
        text: TextSpan(
          text: AuthStrings.dontHaveAccount,
          style: AppTextStyles.urbanistFont15Grey700Regular1_33,
          children: [
            TextSpan(
              text: AuthStrings.signUp,
              style: AppTextStyles.urbanistFont15Grey700SemiBold1_33,
              recognizer: TapGestureRecognizer()
                ..onTap =
                    () => Navigator.of(context).pushNamed(RoutesName.signup),
            ),
          ],
        ),
      ),
    );
  }
}
