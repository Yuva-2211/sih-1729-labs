import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color onError = Color(0xFFffffff);
  static const Color error = Color(0xFFba1a1a);
  static const Color onSurfaceVariant = Color(0xFF464553);
  static const Color secondaryFixedDim = Color(0xFFffb694);
  static const Color secondaryContainer = Color(0xFFffa67b);
  static const Color onPrimaryFixedVariant = Color(0xFF3533b0);
  static const Color primaryContainer = Color(0xFF5b5bd6);
  static const Color onErrorContainer = Color(0xFF93000a);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color onPrimaryFixed = Color(0xFF0a006b);
  static const Color onPrimaryContainer = Color(0xFFedeaff);
  static const Color surface = Color(0xFFf9f9f7);
  static const Color tertiaryFixedDim = Color(0xFFffb77e);
  static const Color inversePrimary = Color(0xFFc1c1ff);
  static const Color background = Color(0xFFf9f9f7);
  static const Color surfaceContainer = Color(0xFFeeeeec);
  static const Color tertiaryFixed = Color(0xFFffdcc3);
  static const Color surfaceContainerHighest = Color(0xFFe2e3e1);
  static const Color onTertiary = Color(0xFFffffff);
  static const Color primaryFixedDim = Color(0xFFc1c1ff);
  static const Color onTertiaryFixedVariant = Color(0xFF6e3900);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color primary = Color(0xFF4241bc);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color onSecondaryFixedVariant = Color(0xFF733513);
  static const Color inverseOnSurface = Color(0xFFf1f1ef);
  static const Color tertiary = Color(0xFF804300);
  static const Color onTertiaryFixed = Color(0xFF2f1500);
  static const Color surfaceTint = Color(0xFF4e4ec9);
  static const Color surfaceContainerLow = Color(0xFFf4f4f2);
  static const Color onBackground = Color(0xFF1a1c1b);
  static const Color onSurface = Color(0xFF1a1c1b);
  static const Color surfaceDim = Color(0xFFdadad8);
  static const Color onSecondaryFixed = Color(0xFF351000);
  static const Color surfaceContainerHigh = Color(0xFFe8e8e6);
  static const Color tertiaryContainer = Color(0xFFa35700);
  static const Color surfaceVariant = Color(0xFFe2e3e1);
  static const Color secondary = Color(0xFF914c28);
  static const Color secondaryFixed = Color(0xFFffdbcc);
  static const Color onSecondaryContainer = Color(0xFF793917);
  static const Color outline = Color(0xFF777585);
  static const Color surfaceBright = Color(0xFFf9f9f7);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color outlineVariant = Color(0xFFc7c4d6);
  static const Color primaryFixed = Color(0xFFe2dfff);
  static const Color onTertiaryContainer = Color(0xFFffe8d9);
  static const Color inverseSurface = Color(0xFF2f3130);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.surfaceTint,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * 32,
          height: 40 / 32,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 28,
          height: 36 / 28,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 22,
          height: 28 / 22,
          color: AppColors.onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          height: 32 / 24,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 22 / 15,
          color: AppColors.onSurface,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.01 * 13,
          height: 18 / 13,
          color: AppColors.onSurface,
        ),
      ),
      useMaterial3: true,
    );
  }
}
