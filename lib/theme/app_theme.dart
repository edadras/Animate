import 'package:flutter/material.dart';

/// Premium, warm "Istanbul at golden hour" palette.
class AppColors {
  static const navy = Color(0xFF0B1D2A);
  static const navy2 = Color(0xFF12304A);
  static const gold = Color(0xFFFFC93C);
  static const ember = Color(0xFFE0552B);
  static const teal = Color(0xFF1ABC9C);
  static const sky = Color(0xFF4AA3DF);
  static const cream = Color(0xFFF6EFE2);
  static const glass = Color(0x33FFFFFF);
  static const glassDark = Color(0x99081826);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.navy,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.teal,
          surface: AppColors.navy2,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      );

  static BoxDecoration glassCard({double radius = 20}) => BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8))],
      );

  static const goldGradient = LinearGradient(
    colors: [AppColors.gold, AppColors.ember],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const skyGradient = LinearGradient(
    colors: [AppColors.navy2, AppColors.navy],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
