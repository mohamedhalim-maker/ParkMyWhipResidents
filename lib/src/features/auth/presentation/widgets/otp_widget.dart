import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpWidget extends StatelessWidget {
  const OtpWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.errorMessage,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorMessage != null && errorMessage!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 17.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PinCodeTextField(
            length: 6,
            hintCharacter: '0',
            obscureText: false,
            autoFocus: true,
            cursorColor: AppColor.richRed,
            hintStyle: AppTextStyles.urbanistFont16Grey800Opacity40Regular1_3,
            textStyle: AppTextStyles.urbanistFont16BlackRegular1_2,
            animationType: AnimationType.fade,
            backgroundColor: Colors.transparent,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10.r),
              fieldHeight: 44.h,
              fieldWidth: 44.w,
              activeFillColor: AppColor.white,
              selectedFillColor: AppColor.white,
              inactiveFillColor: AppColor.white,
              activeColor: hasError ? AppColor.red : AppColor.grey300,
              selectedColor: hasError ? AppColor.red : AppColor.grey800,
              inactiveColor: hasError ? AppColor.red : AppColor.grey300,
              errorBorderColor: AppColor.red,
            ),
            animationDuration: Duration(milliseconds: 300),
            enableActiveFill: true,
            controller: controller,
            onChanged: (value) {
              onChanged();
            },
            beforeTextPaste: (text) {
              return true;
            },
            appContext: context,
          ),
          Text(
            errorMessage ?? '',
            style: AppTextStyles.urbanistFont12Red500Regular1_5,
          ),
        ],
      ),
    );
  }
}

//
