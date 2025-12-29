import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/widgets/account_text_toggle.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';

class DontHaveAccountText extends StatelessWidget {
  const DontHaveAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountTextToggle(
      normalText: AuthStrings.dontHaveAccount,
      actionText: AuthStrings.signUp,
      onTap: () => getIt<LoginCubit>().navigateToSignupPage(context: context),
    );
  }
}
