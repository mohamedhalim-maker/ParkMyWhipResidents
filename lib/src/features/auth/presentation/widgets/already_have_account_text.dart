import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';

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
              ..onTap = () =>
                  getIt<SignupCubit>().navigateBackToLogin(context: context),
          ),
        ],
      ),
    );
  }
}
