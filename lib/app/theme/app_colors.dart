import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF022960);
  static const Color secondary = Color(0xFFffffff);
  static const Color tertiary = Color(0xFF04639C);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
}

abstract final class AppColorsDark {
  static const Color primary = Color(0xFF1E3A5F);
  static const Color secondary = Color(0xFF121212);
  static const Color tertiary = Color(0xFF2196F3);
  static const Color surface = Color(0xFF0D0D15);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final Color error;
  final Color success;
  final Color warning;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;

  const AppColorsExtension({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.error,
    required this.success,
    required this.warning,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
  });

  static const light = AppColorsExtension(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.tertiary,
    surface: AppColors.surface,
    error: AppColors.error,
    success: AppColors.success,
    warning: AppColors.warning,
    cardBackground: AppColors.primary,
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
  );

  static const dark = AppColorsExtension(
    primary: AppColorsDark.primary,
    secondary: AppColorsDark.secondary,
    tertiary: AppColorsDark.tertiary,
    surface: AppColorsDark.surface,
    error: AppColorsDark.error,
    success: AppColorsDark.success,
    warning: AppColorsDark.warning,
    cardBackground: AppColorsDark.primary,
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
  );

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? surface,
    Color? error,
    Color? success,
    Color? warning,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      surface: surface ?? this.surface,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}
