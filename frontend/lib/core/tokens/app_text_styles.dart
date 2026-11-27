import 'package:flutter/material.dart';
import 'package:libri_flow/core/theme/theme.dart';

/// @deprecated Use `IvoryTheme` directly instead.
///
/// This class is maintained for backwards compatibility only.
/// All typography tokens have been consolidated into `IvoryTheme`.
///
/// Migration guide:
/// - OLD: `AppTextStyles.smallCapsLabel`
/// - NEW: `IvoryTheme.smallCapsLabel`
///
/// Import:
/// ```dart
/// import 'package:libri_flow/core/theme/theme.dart';
/// ```
///
/// OLD (deprecated pattern):
/// ```dart
/// import 'package:libri_flow/core/tokens/app_tokens.dart';
/// Text('Label', style: AppTextStyles.smallCapsLabel); // ❌ Don't use
/// ```
///
/// NEW (recommended pattern):
/// ```dart
/// import 'package:libri_flow/core/theme/theme.dart';
/// Text('Label', style: IvoryTheme.smallCapsLabel); // ✅ Use this
/// ```
class AppTextStyles {
  @Deprecated('Use IvoryTheme.smallCapsLabel instead')
  static TextStyle get smallCapsLabel => IvoryTheme.smallCapsLabel;

  @Deprecated('Use IvoryTheme.smallCapsLabelXWide instead')
  static TextStyle get smallCapsLabelXWide => IvoryTheme.smallCapsLabelXWide;

  @Deprecated('Use IvoryTheme.priceSmall instead')
  static TextStyle get priceSmall => IvoryTheme.priceSmall;

  @Deprecated('Use IvoryTheme.priceMedium instead')
  static TextStyle get priceMedium => IvoryTheme.priceMedium;

  @Deprecated('Use IvoryTheme.priceLarge instead')
  static TextStyle get priceLarge => IvoryTheme.priceLarge;

  @Deprecated('Use IvoryTheme.quote instead')
  static TextStyle get quote => IvoryTheme.quote;

  @Deprecated('Use IvoryTheme.buttonLabel instead')
  static TextStyle get buttonLabel => IvoryTheme.buttonLabel;

  @Deprecated('Use IvoryTheme.buttonLabelWideSpacing instead')
  static TextStyle get buttonLabelWideSpacing =>
      IvoryTheme.buttonLabelWideSpacing;

  @Deprecated('Use IvoryTheme.dialogTitle instead')
  static TextStyle get dialogTitle => IvoryTheme.dialogTitle;

  @Deprecated('Use IvoryTheme.dialogMessage instead')
  static TextStyle get dialogMessage => IvoryTheme.dialogMessage;

  @Deprecated('Use IvoryTheme.dialogButton instead')
  static TextStyle get dialogButton => IvoryTheme.dialogButton;

  @Deprecated('Use IvoryTheme.formFieldLabel instead')
  static TextStyle get formFieldLabel => IvoryTheme.formFieldLabel;

  @Deprecated('Use IvoryTheme.statusLabel instead')
  static TextStyle get statusLabel => IvoryTheme.statusLabel;

  @Deprecated('Use IvoryTheme.heroHeading instead')
  static TextStyle get heroHeading => IvoryTheme.heroHeading;

  @Deprecated('Use IvoryTheme.bodyLargeBold instead')
  static TextStyle get bodyLargeBold => IvoryTheme.bodyLargeBold;

  @Deprecated('Use IvoryTheme.hintText instead')
  static TextStyle get hintText => IvoryTheme.hintText;

  @Deprecated('Use IvoryTheme.sectionHeaderSmall instead')
  static TextStyle get sectionHeaderSmall => IvoryTheme.sectionHeaderSmall;
}
