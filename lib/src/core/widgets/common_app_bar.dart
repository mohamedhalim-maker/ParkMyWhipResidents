import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({super.key, this.onBackPress});
  final Function()? onBackPress;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: CircleAvatar(
          radius: 37,
          backgroundColor: AppColor.grey200,
          child: IconButton(
            onPressed: onBackPress ??
                () => Navigator.pop(context), //go back to previous page
            icon: Icon(
              AppIcons.backIcon,
              size: 18,
              color: AppColor.grey700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
