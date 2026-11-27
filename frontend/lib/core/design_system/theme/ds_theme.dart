import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_typography.dart';

abstract class DSTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DSColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DSColors.forestGreen,
        primary: DSColors.forestGreen,
        secondary: DSColors.warmGold,
        tertiary: DSColors.terracotta,
        surface: DSColors.surface,
        error: DSColors.error,
        onPrimary: DSColors.textInverse,
        onSecondary: DSColors.textInverse,
        onSurface: DSColors.textDark,
        onError: DSColors.textInverse,
      ),
      textTheme: DSTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: DSColors.forestGreen),
        titleTextStyle: TextStyle(
          color: DSColors.forestGreen,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.deepArchiveGreen,
          foregroundColor: DSColors.textInverse,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: DSTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DSColors.deepArchiveGreen,
          side: const BorderSide(color: DSColors.border, width: 1.2),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: DSTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DSColors.forestGreen,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: DSTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DSColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        hintStyle: DSTypography.textTheme.bodyMedium?.copyWith(
          color: DSColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DSColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DSColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DSColors.forestGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DSColors.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: DSColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.lg),
          side: const BorderSide(color: DSColors.borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DSColors.surfaceVariant,
        selectedColor: DSColors.deepArchiveGreen,
        labelStyle: DSTypography.textTheme.bodySmall?.copyWith(
          color: DSColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: DSTypography.textTheme.bodySmall?.copyWith(
          color: DSColors.textInverse,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.pill),
          side: BorderSide(
            color: DSColors.deepArchiveGreen.withValues(alpha: 0.15),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DSColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.lg),
        ),
        titleTextStyle: DSTypography.textTheme.titleLarge,
        contentTextStyle: DSTypography.textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DSColors.forestGreen,
        contentTextStyle: DSTypography.textTheme.bodyMedium?.copyWith(
          color: DSColors.textInverse,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
