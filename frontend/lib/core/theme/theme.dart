import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/tokens/ds_colors.dart';

/// Centralized Ivory Theme for The Tactile Archive app
///
/// Unifies typography (Playfair Display serif headers + Inter sans-serif body),
/// brand colors (Forest Green, Warm Cream, Terracotta, Warm Gold, Soft Mint, Light Blue),
/// rounded card surfaces, input fields, buttons, and subtle shadows across web and mobile.
class IvoryTheme {
  static const List<String> sansFallbacks = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const List<String> serifFallbacks = [
    'Playfair Display',
    'Georgia',
    'Cambria',
    'Times New Roman',
    'serif',
  ];

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamilyFallback: sansFallbacks,
      scaffoldBackgroundColor: DSColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DSColors.forestGreen,
        primary: DSColors.forestGreen,
        onPrimary: DSColors.textInverse,
        secondary: DSColors.warmGold,
        onSecondary: DSColors.textInverse,
        tertiary: DSColors.terracotta,
        onTertiary: DSColors.textInverse,
        surface: DSColors.surface,
        onSurface: DSColors.textDark,
        error: DSColors.error,
        onError: DSColors.textInverse,
        outline: DSColors.border,
        outlineVariant: DSColors.borderLight,
      ),
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: DSColors.forestGreen),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.deepArchiveGreen,
          foregroundColor: DSColors.textInverse,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DSColors.deepArchiveGreen,
          side: const BorderSide(color: DSColors.border, width: 1.2),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
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
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: DSColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DSColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DSColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DSColors.deepArchiveGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DSColors.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: DSColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: DSColors.softBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DSColors.surfaceVariant,
        selectedColor: DSColors.deepArchiveGreen,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: DSColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: DSColors.textInverse,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: DSColors.deepArchiveGreen.withValues(alpha: 0.15),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DSColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: DSColors.charcoal,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: DSColors.textDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DSColors.forestGreen,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: DSColors.textInverse,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: DSColors.charcoal,
        letterSpacing: -1.12,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: DSColors.charcoal,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: DSColors.charcoal,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: DSColors.charcoal,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: DSColors.charcoal,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: DSColors.charcoal,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DSColors.textDark,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DSColors.textDark,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.6,
        color: DSColors.textDark,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: DSColors.textDark,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.5,
        color: DSColors.textLight,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DSColors.charcoal,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DSColors.textDark,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: DSColors.textMuted,
      ),
    );
  }

  static TextStyle _labelSmallVariant({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    return _textTheme.labelSmall!.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
  }

  static TextStyle _bodyMediumVariant({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return _textTheme.bodyMedium!.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _bodyLargeVariant({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return _textTheme.bodyLarge!.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ============================================================================
  // CUSTOM TYPOGRAPHY TOKENS (Tactile Archive-specific)
  // ============================================================================

  static TextStyle get smallCapsLabel => _labelSmallVariant(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.4,
  );

  static TextStyle get smallCapsLabelXWide => _labelSmallVariant(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 3.0,
    color: DSColors.textLight,
  );

  static TextStyle get priceSmall =>
      _bodyMediumVariant(fontSize: 10, fontWeight: FontWeight.bold);

  static TextStyle get priceMedium => _bodyMediumVariant(
    fontWeight: FontWeight.bold,
    color: DSColors.textDark,
  );

  static TextStyle get priceLarge => _bodyLargeVariant(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: DSColors.charcoal,
  );

  static TextStyle get quote => GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontStyle: FontStyle.italic,
    height: 1.5,
    color: DSColors.charcoal,
  );

  static TextStyle get buttonLabel => _labelSmallVariant(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: DSColors.textInverse,
  );

  static TextStyle get buttonLabelWideSpacing => _labelSmallVariant(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.4,
    color: DSColors.textInverse,
  );

  static TextStyle get dialogTitle => GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: DSColors.charcoal,
    letterSpacing: -0.5,
  );

  static TextStyle get dialogMessage =>
      _bodyMediumVariant(color: DSColors.textLight, height: 1.5);

  static TextStyle get dialogButton => _bodyMediumVariant(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: DSColors.charcoal,
    letterSpacing: 1.2,
  );

  static TextStyle get formFieldLabel => _labelSmallVariant(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: DSColors.textDark,
  );

  static TextStyle get statusLabel => _labelSmallVariant(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static TextStyle get heroHeading => GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: DSColors.charcoal,
  );

  static TextStyle get bodyLargeBold =>
      _bodyLargeVariant(fontWeight: FontWeight.bold);

  static TextStyle get hintText =>
      _bodyMediumVariant(color: DSColors.textMuted);

  static TextStyle get sectionHeaderSmall => _labelSmallVariant(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.4,
    color: DSColors.charcoal,
  );
}
