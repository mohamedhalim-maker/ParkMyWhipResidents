import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/app_style/app_theme.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/routes/router.dart';

class ParkMyWhipResidentApp extends StatelessWidget {
  const ParkMyWhipResidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          navigatorKey: AppRouter.navigatorKey,
          onGenerateRoute: AppRouter.generate,
          initialRoute: AppRouter.getInitialRoute(),
        );
      },
    );
  }
}
