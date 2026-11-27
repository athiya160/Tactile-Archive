import 'package:flutter/material.dart';

abstract class DSShadows {
  /// Subtle natural elevation
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: const Color(0xFF252923).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium layered shadow for editorial cards & dialogs
  static List<BoxShadow> get md => [
    BoxShadow(
      color: const Color(0xFF252923).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF252923).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Large depth shadow for modals, sheets, and lifted cards
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: const Color(0xFF252923).withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: const Color(0xFF252923).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  /// Restrained 3D book card resting shadow with warm ambient undertone
  static List<BoxShadow> get bookCard => [
    BoxShadow(
      color: const Color(0xFF183D32).withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF252923).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Restrained 3D book card lifted hover shadow
  static List<BoxShadow> get bookCardHover => [
    BoxShadow(
      color: const Color(0xFF183D32).withValues(alpha: 0.12),
      blurRadius: 26,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: const Color(0xFFC47C62).withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
