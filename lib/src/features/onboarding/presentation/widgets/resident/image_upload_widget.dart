import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';

/// Reusable widget for uploading documents/images (supports images and PDFs)
///
/// Two states:
/// 1. Empty state: custom icon + custom text + forward arrow
/// 2. Uploaded state:
///    - For images: Shows image preview + document icon + filename + close icon
///    - For PDFs: Shows document icon + filename + close icon (no visual preview)
class ImageUploadWidget extends StatelessWidget {
  final File? image;
  final String? fileName;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final IconData emptyStateIcon;
  final String emptyStateText;
  final bool isImageFile;

  const ImageUploadWidget({
    super.key,
    this.image,
    this.fileName,
    this.isLoading = false,
    required this.onTap,
    this.onRemove,
    this.emptyStateIcon = AppIcons.imageIcon,
    this.emptyStateText = OnboardingStrings.takePhotoOrUpload,
    this.isImageFile = true,
  });

  bool get hasImage => image != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border.all(
            color: AppColor.redAlerts.withValues(alpha: 0.4), width: 0.5.w),
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
          if (hasImage && image != null && isImageFile) ...[
            // Image preview (for actual image files)
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.file(
                image!,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
              ),
            ),
            verticalSpace(16),
          ],
          // Note: For PDF files (!isImageFile), we don't show preview - only icon below

          // Upload container
          GestureDetector(
            onTap: hasImage || isLoading ? null : onTap,
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
                          hasImage ? AppIcons.document : emptyStateIcon,
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
                        : hasImage && fileName != null
                            ? fileName!
                            : emptyStateText,
                    style: AppTextStyles.urbanistFont14RedDarkMedium1,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                horizontalSpace(12),

                // Right icon
                if (!isLoading)
                  GestureDetector(
                    onTap: hasImage ? onRemove : null,
                    child: Icon(
                      hasImage ? AppIcons.close : AppIcons.forwardIcon,
                      color: AppColor.redDark,
                      size: hasImage ? 12.w : 18.w,
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
