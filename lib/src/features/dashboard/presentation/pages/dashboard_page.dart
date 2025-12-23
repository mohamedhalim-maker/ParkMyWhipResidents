import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_manager.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      final authManager = getIt<AuthManager>();
      await authManager.signOut();

      AppLogger.auth('User signed out successfully');

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutesName.login,
          (route) => false,
        );
      }
    } catch (e) {
      AppLogger.error('Sign out failed', error: e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: AppColor.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              verticalSpace(24),
              const Spacer(),
              CommonButton(
                text: 'Sign Out',
                onPressed: () => _handleSignOut(context),
                leadingIcon: AppIcons.logout,
                color: AppColor.red,
              ),
              verticalSpace(16),
            ],
          ),
        ),
      ),
    );
  }
}
