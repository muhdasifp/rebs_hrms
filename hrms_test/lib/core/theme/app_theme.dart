import 'package:flutter/material.dart';
import 'package:hrms_test/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData appTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.bg,

    appBarTheme: AppBarThemeData(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),

    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4361EE),
      brightness: Brightness.light,
    ),
  );
}
