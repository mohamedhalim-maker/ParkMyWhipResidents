import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';

class ResetLinkErrorPage extends StatelessWidget {
  const ResetLinkErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.login,
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColor.red,
                ),
                const SizedBox(height: 24),
                Text(
                  AuthStrings.linkExpiredMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.urbanistFont18Grey800SemiBold1_25,
                ),
                const SizedBox(height: 32),
                CommonButton(
                  text: AuthStrings.goToLoginButton,
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RoutesName.login,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
