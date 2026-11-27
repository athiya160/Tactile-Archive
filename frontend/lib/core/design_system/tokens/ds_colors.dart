import 'package:flutter/material.dart';

/// The Tactile Archive — Editorial Design System Colors
/// Luxury editorial bookstore palette:
/// - Forest Green: #1E3A2F
/// - Warm Ivory: #FBF8F2
/// - Antique Gold: #D4AF37
/// - Midnight Ink: #252923
/// - Muted Text: #77786F
/// - Soft Border: #E7E1D6
/// - White: #FFFFFF
abstract class DSColors {
  // --- Core Editorial Palette ---
  static const Color deepForestGreen = Color(0xFF1E3A2F);
  static const Color secondaryGreen = Color(0xFF285C49);
  static const Color warmIvory = Color(0xFFFBF8F2);
  static const Color paperWhite = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color mutedTerracotta = Color(0xFFC47C62);
  static const Color charcoal = Color(0xFF252923);
  static const Color midnightInk = Color(0xFF252923);
  static const Color softBorder = Color(0xFFE7E1D6);
  static const Color borderLight = Color(0xFFF2ECE1);

  // --- Brand Color Aliases (Full Backward-Compatibility) ---
  static const Color forestGreen = deepForestGreen;
  static const Color forestGreenHover = Color(0xFF142E25);
  static const Color warmCream = warmIvory;
  static const Color warmCreamLight = paperWhite;
  static const Color terracotta = mutedTerracotta;
  static const Color accentTerracotta = mutedTerracotta;
  static const Color terracottaHover = Color(0xFFA8634C);
  static const Color warmGold = Color(0xFFD4AF37);
  static const Color warmGoldLight = Color(0xFFFFF3DC);
  static const Color softMint = Color(0xFFE3EFE9);
  static const Color lightBlue = Color(0xFFEBF8FF);
  static const Color lightBlueAccent = Color(0xFF3182CE);

  // --- Mobile & Editorial Aliases ---
  static const Color deepArchiveGreen = deepForestGreen;
  static const Color warmPaper = warmIvory;
  static const Color softSurface = Color(0xFFF5EFE6);
  static const Color ink = charcoal;
  static const Color mutedText = Color(0xFF77786F);
  static const Color antiqueGold = Color(0xFFD4AF37);

  // --- Design Tokens Aliases ---
  static const Color primary = deepForestGreen;
  static const Color primaryHover = forestGreenHover;
  static const Color secondary = secondaryGreen;
  static const Color secondaryHover = Color(0xFF1F4738);
  static const Color accent = mutedTerracotta;
  static const Color accentHover = terracottaHover;
  static const Color mint = softMint;

  // --- Backgrounds & Surfaces ---
  static const Color background = warmIvory;
  static const Color surface = paperWhite;
  static const Color surfaceVariant = Color(0xFFF2ECE1);

  // --- Typography & Content ---
  static const Color textDark = charcoal;
  static const Color textPrimary = charcoal;
  static const Color textLight = Color(0xFF555C54);
  static const Color textSecondary = Color(0xFF555C54);
  static const Color textMuted = Color(0xFF77786F);
  static const Color textInverse = Color(0xFFFFFFFF);

  // --- Borders & Dividers ---
  static const Color border = softBorder;
  static const Color borderWarm = Color(0xFFF0E5D8);

  // --- Status & Feedback ---
  static const Color error = Color(0xFFC53030);
  static const Color success = Color(0xFF285C49);
  static const Color warning = Color(0xFFD69E2E);
  static const Color info = Color(0xFF2B6CB0);
}
