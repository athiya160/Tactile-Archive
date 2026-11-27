import 'package:flutter/material.dart';
import '../design_system/tokens/ds_colors.dart';

abstract class AppColors {
  // Brand Palette
  static const Color primary = DSColors.forestGreen;
  static const Color primaryContainer = DSColors.forestGreenHover;
  static const Color onPrimary = Colors.white;

  static const Color warmCream = DSColors.warmCream;
  static const Color warmCreamLight = DSColors.warmCreamLight;
  static const Color terracotta = DSColors.terracotta;
  static const Color warmGold = DSColors.warmGold;
  static const Color softMint = DSColors.softMint;
  static const Color lightBlue = DSColors.lightBlue;
  static const Color lightBlueAccent = DSColors.lightBlueAccent;

  static const Color surface = DSColors.warmCreamLight;
  static const Color onSurface = DSColors.textDark;
  static const Color onSurfaceVariant = DSColors.textLight;

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = DSColors.warmCream;
  static const Color surfaceContainer = Color(0xFFF4F4EE);
  static const Color surfaceContainerHigh = Color(0xFFEEEEE8);
  static const Color surfaceContainerHighest = Color(0xFFE2E3DF);

  static const Color secondaryContainer = DSColors.softMint;
  static const Color onSecondaryContainer = DSColors.forestGreen;

  static const Color tertiary = DSColors.warmGold;
  static const Color onTertiary = Colors.white;

  static const Color error = DSColors.error;
  static const Color onError = Colors.white;

  static const Color outline = DSColors.border;
  static const Color outlineVariant = Color(0x26C3C8C1);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

abstract class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

abstract class AppShadows {
  static List<BoxShadow> ambient = [
    BoxShadow(
      color: AppColors.onSurface.withValues(alpha: 0.06),
      blurRadius: 32,
      offset: Offset.zero,
    ),
  ];

  static List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}

abstract class AppTransitions {
  static const Curve defaultCurve = Cubic(0.25, 0.8, 0.25, 1.0);
  static const Duration defaultDuration = Duration(milliseconds: 300);
}
