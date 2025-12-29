import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';

/// Shows a bottom sheet for selecting image source (gallery or camera)
void showImageSourceBottomSheet({
  required BuildContext context,
  required Function(ImageSource) onSourceSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColor.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => _ImageSourceBottomSheet(
      onSourceSelected: onSourceSelected,
    ),
  );
}

class _ImageSourceBottomSheet extends StatelessWidget {
  final Function(ImageSource) onSourceSelected;

  const _ImageSourceBottomSheet({required this.onSourceSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ImagePickerStrings.choosePhotoSource,
                style: AppTextStyles.urbanistFont18Grey800SemiBold1_25,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  AppIcons.close,
                  size: 12.w,
                  color: AppColor.black,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          verticalSpace(24),

          // Gallery option
          _ImageSourceOption(
            icon: AppIcons.imageIcon,
            label: ImagePickerStrings.gallery,
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.gallery);
            },
          ),

          verticalSpace(16),

          // Camera option
          _ImageSourceOption(
            icon: AppIcons.imageIcon,
            label: ImagePickerStrings.camera,
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.camera);
            },
          ),

          verticalSpace(24),
        ],
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.grey300),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColor.gray100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                size: 20.w,
                color: AppColor.grey700,
              ),
            ),
            horizontalSpace(12),
            Text(
              label,
              style: AppTextStyles.urbanistFont16Grey800Medium1_2,
            ),
            const Spacer(),
            Icon(
              AppIcons.forwardIcon,
              size: 16.w,
              color: AppColor.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
