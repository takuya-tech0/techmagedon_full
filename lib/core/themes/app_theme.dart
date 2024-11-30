// lib/core/themes/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // ブランドカラー
  static const Color primary = Colors.purple;
  static const Color primaryLight = Color(0xFFE8DFFA);
  static const Color secondary = Color(0xFFFFE4E8);


  // 基本カラー
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF5F5F5);
  static const Color error = Colors.red;


  // テキストカラー
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);


  // その他
  static const Color divider = Color(0xFFE0E0E0);
  static const Color overlay = Colors.black26;
}


class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );


  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );


  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );


  static const TextStyle body1 = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );


  static const TextStyle body2 = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );


  static const TextStyle caption = TextStyle(
    fontSize: 10,
    color: AppColors.textSecondary,
  );
}


class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;


  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
}


class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double xl = 24.0;


  static BorderRadius get smallAll => BorderRadius.circular(sm);
  static BorderRadius get mediumAll => BorderRadius.circular(md);
  static BorderRadius get largeAll => BorderRadius.circular(lg);
  static BorderRadius get extraLargeAll => BorderRadius.circular(xl);
}


class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),

      // AppBar テーマ
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
      ),

      // ボトムナビゲーションテーマ
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
      ),

      // TabBar テーマ
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.body1,
        unselectedLabelStyle: AppTextStyles.body2,
      ),

      // Card テーマ
      cardTheme: CardTheme(
        color: AppColors.background,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mediumAll,
        ),
        margin: AppSpacing.paddingSM,
      ),

      // TextField テーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.largeAll,
          borderSide: BorderSide.none,
        ),
        hintStyle: AppTextStyles.body2,
        contentPadding: AppSpacing.paddingMD,
      ),

      // Button テーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mediumAll,
          ),
          padding: AppSpacing.paddingMD,
        ),
      ),

      // Icon テーマ
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
