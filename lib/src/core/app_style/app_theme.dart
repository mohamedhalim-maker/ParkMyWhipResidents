import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColor.white,
      primaryColor: AppColor.richRed,
      colorScheme: ColorScheme.light(
        primary: AppColor.richRed,
        secondary: AppColor.grey800,
        surface: AppColor.white,
        error: AppColor.red,
        onPrimary: AppColor.white,
        onSecondary: AppColor.white,
        onSurface: AppColor.grey800,
        onError: AppColor.white,
      ),
      fontFamily: 'Urbanist',
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColor.grey800),
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: AppColor.grey800,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.richRed,
          foregroundColor: AppColor.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColor.grey200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColor.grey200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColor.richRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColor.red, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      
      cardTheme: CardThemeData(
        color: AppColor.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: AppColor.grey200, width: 1),
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: AppColor.grey200,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
