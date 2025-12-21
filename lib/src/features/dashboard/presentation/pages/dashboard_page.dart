import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   'Welcome to ParkMyWhip',
            //   style: AppTextStyles.urbanistFont24Grey800SemiBold1_3,
            // ),
            verticalSpace(8),
            // Text(
            //   'Manage your parking, vehicles, and guest passes',
            //   style: AppTextStyles.urbanistFont16Grey700Regular1_5,
            // ),
            verticalSpace(32),
            _buildFeatureCard(
              context,
              icon: Icons.local_parking,
              title: 'My Parking Spot',
              description: 'View and manage your assigned parking spot',
              color: AppColor.richRed,
              onTap: () {},
            ),
            verticalSpace(16),
            // _buildFeatureCard(
            //   context,
            //   icon: Icons.directions_car,
            //   title: 'My Vehicles',
            //   description: 'Add and manage your vehicles',
            //   color: AppColor.blue,
            //   onTap: () {},
            // ),
            // verticalSpace(16),
            // _buildFeatureCard(
            //   context,
            //   icon: Icons.card_membership,
            //   title: 'Guest Passes',
            //   description: 'Create and manage guest parking passes',
            //   color: AppColor.green,
            //   onTap: () {},
            // ),
            // verticalSpace(16),
            // _buildFeatureCard(
            //   context,
            //   icon: Icons.warning_amber,
            //   title: 'Violations',
            //   description: 'View parking violations and payments',
            //   color: AppColor.orange,
            //   onTap: () {},
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 28.sp, color: color),
              ),
              horizontalSpace(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   title,
                    //   style: AppTextStyles.urbanistFont16Grey800SemiBold1_5,
                    // ),
                    verticalSpace(4),
                    // Text(
                    //   description,
                    //   style: AppTextStyles.urbanistFont14Grey700Regular1_4,
                    // ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 24.sp, color: AppColor.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
