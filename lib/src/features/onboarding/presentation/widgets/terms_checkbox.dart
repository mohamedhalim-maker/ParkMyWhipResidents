import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';

/// Reusable checkbox widget for terms and conditions acceptance
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    this.text = '',
    this.value = false,
    this.onChanged,
  });

  final String text;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20.w,
          height: 20.h,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        horizontalSpace(8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.urbanistFont15Grey700Regular1_33,
          ),
        ),
      ],
    );
  }
}
