import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';

/// Reusable widget for uploading driving license
///
/// Two states:
/// 1. Empty state: imageIcon + "Take Photo or Upload" + forward arrow
/// 2. Uploaded state: Shows image preview + document icon + filename + close icon
class LicenseUploadWidget extends StatelessWidget {
  final File? licenseImage;
  final String? licenseFileName;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const LicenseUploadWidget({
    super.key,
    this.licenseImage,
    this.licenseFileName,
    this.isLoading = false,
    required this.onTap,
    this.onRemove,
  });

  bool get hasLicense => licenseImage != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border.all(color: AppColor.redAlerts.withValues(alpha: 0.4), width: 0.5.w),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColor.grey400.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLicense && licenseImage != null) ...[
            // Image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.file(
                licenseImage!,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
              ),
            ),
            verticalSpace(16),
          ],

          // Upload container
          GestureDetector(
            onTap: hasLicense || isLoading ? null : onTap,
            child: Row(
              children: [
                // Left icon with red container
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColor.richRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColor.richRed,
                          ),
                        )
                      : Icon(
                          hasLicense ? AppIcons.document : AppIcons.imageIcon,
                          color: AppColor.richRed,
                          size: 20.w,
                        ),
                ),

                horizontalSpace(12),

                // Middle text
                Expanded(
                  child: Text(
                    isLoading
                        ? 'Loading...'
                        : hasLicense && licenseFileName != null
                            ? licenseFileName!
                            : OnboardingStrings.takePhotoOrUpload,
                    style: AppTextStyles.urbanistFont14RedDarkMedium1,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                horizontalSpace(12),

                // Right icon
                if (!isLoading)
                  GestureDetector(
                    onTap: hasLicense ? onRemove : null,
                    child: Icon(
                      hasLicense ? AppIcons.close : AppIcons.forwardIcon,
                      color: AppColor.redDark,
                      size: 18.w,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
