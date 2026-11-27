# Typography Migration Implementation Guide

## Overview

This guide walks through applying the typography consistency fixes identified in `TYPOGRAPHY_AUDIT_REPORT.md`. The consolidated `IvoryTheme` class (in `lib/core/theme/theme.dart`) now includes both standard `TextTheme` and custom typography tokens.

## Quick Start

### Step 1: Verify IvoryTheme Typography is Available
```dart
// In any file, you can now use:
import 'package:new_flutter/core/theme/theme.dart';

// Standard Material theme styles (via context):
Theme.of(context).textTheme.headlineSmall

// Custom Tactile Archive tokens (direct access):
IvoryTheme.smallCapsLabel
IvoryTheme.buttonLabel
IvoryTheme.quote
IvoryTheme.dialogTitle
```

### Step 2: Run These Commands to Check Current State
```bash
# Analyze the codebase for issues
flutter analyze

# Check for unused imports (to be run after patches)
dart fix --dry-run
```

---

## Phase 1: Patch Core Widgets (High Impact)

These are the most-used widgets. Fixing them will resolve many issues.

### 1.1: Fix `lib/core/widgets/ivory_dialog.dart`

**Current State:** Dialog title, message, and buttons all use hardcoded TextStyle

**Changes to Make:**
```dart
// Find and replace these three Text widgets:

// 1. Title (around line 76-81)
- style: const TextStyle(
-   fontFamily: 'Noto Serif',
-   fontSize: 20,
-   fontWeight: FontWeight.bold,
-   color: AppColors.primary,
-   letterSpacing: -0.5,
- ),
+ style: IvoryTheme.dialogTitle,

// 2. Message (around line 87-91)
- style: const TextStyle(
-   fontFamily: 'Manrope',
-   fontSize: 14,
-   color: AppColors.onSurfaceVariant,
-   height: 1.5,
- ),
+ style: IvoryTheme.dialogMessage,

// 3. Button Label (around line 105-110)
- style: const TextStyle(
-   fontFamily: 'Manrope',
-   fontSize: 12,
-   fontWeight: FontWeight.bold,
-   color: AppColors.outline,
-   letterSpacing: 1.2,
- ),
+ style: IvoryTheme.dialogButton,
```

**Required Import:**
```dart
import 'package:new_flutter/core/theme/theme.dart';
```

### 1.2: Fix `lib/core/widgets/ivory_button.dart`

**Current State:** Button labels defined inline per button type

**Changes to Make:**
```dart
// Ghost button label (around line 49-54)
- fontSize: 10,
- fontWeight: FontWeight.bold,
- letterSpacing: 1.2,
+ Use: IvoryTheme.buttonLabel

// Primary button label (around line 102-107)
- fontSize: 10,
- letterSpacing: 2.4,
- fontWeight: FontWeight.bold,
+ Use: IvoryTheme.buttonLabelWideSpacing
```

**Simplified Pattern:**
```dart
// For ghost button
style: textStyle ?? IvoryTheme.buttonLabel.copyWith(
  color: AppColors.onSurfaceVariant,
),

// For primary button
style: textStyle ?? IvoryTheme.buttonLabelWideSpacing,
```

**Required Import:**
```dart
import 'package:new_flutter/core/theme/theme.dart';
```

### 1.3: Fix `lib/core/widgets/ivory_scaffold.dart`

**Current State:** App bar title uses hardcoded Noto Serif + bold

**Location:** Around line 101-102

**Change:**
```dart
- fontFamily: 'Noto Serif',
- fontWeight: FontWeight.bold,
+ style: Theme.of(context).textTheme.headlineSmall,
```

---

## Phase 2: Patch High-Volume Files

These files have multiple style overrides.

### 2.1: Fix `lib/features/activity/presentation/pages/activity_page.dart`

**Issues:** Multiple inline styles for section headers and labels

**Key Patterns to Replace:**

1. **Section Headers** (e.g., "Updates & Interactions") around line 89-91:
```dart
// Before
style: textTheme.labelSmall?.copyWith(
  fontSize: 10,
  fontWeight: FontWeight.bold,
  letterSpacing: 2.4,
  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
),

// After
style: IvoryTheme.smallCapsLabel.copyWith(
  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
),
```

2. **"Archived earlier" Header** (around line 117-118):
```dart
// Before
style: textTheme.labelSmall?.copyWith(
  fontWeight: FontWeight.w700,
  letterSpacing: 3.0,
),

// After
style: IvoryTheme.smallCapsLabelXWide,
```

3. **Activity Card Titles** (around line 189-190):
```dart
// Before
style: textStyle.copyWith(
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
),

// After
style: IvoryTheme.statusLabel,
```

4. **Button copyWith** (around line 284, 303):
```dart
// Before
textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.5),

// After
textStyle: IvoryTheme.buttonLabel,
```

### 2.2: Fix `lib/features/profile/presentation/pages/profile_page.dart`

**Issues:** Profile header with hardcoded fonts, label styling

**Changes:**

1. **Profile Section Label** (around line 117-120):
```dart
// Before
style: Theme.of(context).textTheme.labelSmall?.copyWith(
  fontWeight: FontWeight.bold,
  letterSpacing: 2.4,
  fontSize: 10,
),

// After
style: IvoryTheme.smallCapsLabel,
```

2. **Profile Hero Title** (around line 145-148):
```dart
// Before
style: const TextStyle(
  fontFamily: 'Noto Serif',
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
),

// After
style: Theme.of(context).textTheme.headlineSmall,
```

### 2.3: Fix `lib/features/delivery_address/presentation/widgets/add_address_form.dart`

**Issues:** Form field labels with custom sizes and spacing

**Pattern** (appears multiple times around lines 175-178, 218-221):
```dart
// Before
style: TextStyle(
  fontWeight: FontWeight.bold,
  letterSpacing: 2.0,
  fontSize: 10,
  color: AppColors.onSurfaceVariant,
),

// After
style: IvoryTheme.formFieldLabel.copyWith(
  color: AppColors.onSurfaceVariant,
),
```

Also find and update:
```dart
// Around line 189
- hintStyle: TextStyle(color: AppColors.outline.withValues(alpha: 0.5)),
+ hintStyle: IvoryTheme.hintText,
```

### 2.4: Fix `lib/features/book_details/presentation/widgets/quote_card.dart`

**Issues:** Quote and attribution styling hardcoded

**Changes:**

1. **Quote Text** (lines 23-27):
```dart
// Before
style: const TextStyle(
  fontFamily: 'Noto Serif',
  fontSize: 18,
  fontStyle: FontStyle.italic,
  height: 1.5,
  color: AppColors.primary,
),

// After
style: IvoryTheme.quote,
```

2. **Attribution** (lines 33-34):
```dart
// Before
style: const TextStyle(
  fontSize: 10,
  ...
),

// After
style: IvoryTheme.smallCapsLabel,
```

---

## Phase 3: Bulk Remove Font Family Declarations

Use VS Code's Find & Replace with Regex to quickly remove hardcoded font families.

### 3.1: Remove Noto Serif Declarations
1. **Uncomment these files to target files in lib/features** and **lib/core/widgets**:
2. Open **Find & Replace** (Ctrl+H)
3. Enable **Regex** (Alt+R)
4. **Find:** `fontFamily:\s*'Noto Serif',?\s*`
5. **Replace:** (leave empty)
6. Click **Replace All** (review first with Preview)

**Files to explicitly check after bulk replace:**
- `lib/features/library/presentation/widgets/rental_item_card.dart`
- `lib/features/library/presentation/widgets/uploads_tab.dart`
- `lib/features/cart/presentation/widgets/`.dart files
- `lib/features/book_owner_details/presentation/widgets/owner_bottom_action_bar.dart`

### 3.2: Remove Manrope Declarations
1. **Find:** `fontFamily:\s*'Manrope',?\s*`
2. **Replace:** (leave empty)

**Files to check:**
- `lib/features/support/presentation/widgets/`.dart files
- `lib/features/library/presentation/pages/library_page.dart`

---

## Phase 4: Convert Remaining Inline Styles

### 4.1: Small Label Styles (< 50 occurrences)
**Pattern to find:** `fontSize: 10,.*fontWeight: FontWeight.bold`

**Replacements:**
```dart
// If letterSpacing: 2.4
=> Use: IvoryTheme.smallCapsLabel

// If letterSpacing: 3.0
=> Use: IvoryTheme.smallCapsLabelXWide

// If letterSpacing: 2.0
=> Use: IvoryTheme.formFieldLabel

// If letterSpacing: 1.2
=> Use: IvoryTheme.statusLabel
```

### 4.2: Price Styles
**Files:** `lib/core/widgets/price_row.dart`

**Pattern:**
```dart
// Before (fontSize 10)
=> Use: IvoryTheme.priceSmall

// Before (fontSize 14)
=> Use: IvoryTheme.priceMedium

// Before (fontSize 20)
=> Use: IvoryTheme.priceLarge
```

### 4.3: Rating/Status Chips
**Files:** `lib/core/widgets/rating_chip.dart`, `lib/features/book_owner_details/presentation/widgets/owner_status_indicator.dart`

**Change:** `fontSize: 12, fontWeight: bold`
```dart
=> Use: Theme.of(context).textTheme.labelSmall
   or: IvoryTheme.statusLabel
```

---

## Phase 5: Verification Checklist

After applying patches, run this verification:

### 5.1: Check No Errors
```bash
flutter analyze
```

### 5.2: Verify Imports
Make sure files modified import AppTextStyles:
```dart
import 'package:new_flutter/core/tokens/app_tokens.dart';
```

### 5.3: Manual Spot Check
Open 3-4 edited files and verify:
- [ ] No more `fontFamily: 'Noto Serif'` or `fontFamily: 'Manrope'`
- [ ] All Text style assignments use either `Theme.of(context).textTheme.*` or `AppTextStyles.*`
- [ ] No remaining `const TextStyle(fontFamily: ...)`

### 5.4: Run Tests
```bash
flutter test
```

### 5.5: Visual Test on Device/Emulator
```bash
flutter run
```

Navigate through screens to verify styling looks correct (no broken layouts, fonts render properly).

---

## Rollback Instructions

If something goes wrong, you can rollback changes:

```bash
# Rollback all changes to tracked files
git checkout -- lib/

# Or rollback specific file
git checkout -- lib/core/widgets/ivory_dialog.dart
```

---

## File-by-File Patch Summary

| File | Patches | Token (via IvoryTheme) | Status |
|------|---------|----------------------|--------|
| `ivory_dialog.dart` | 3 | `dialogTitle`, `dialogMessage`, `dialogButton` | Ready |
| `ivory_button.dart` | 2 | `buttonLabel`, `buttonLabelWideSpacing` | Ready |
| `ivory_scaffold.dart` | 1 | Theme: `headlineSmall` | Ready |
| `activity_page.dart` | 6+ | `smallCapsLabel`, `statusLabel`, `buttonLabel` | Ready |
| `profile_page.dart` | 2 | `smallCapsLabel`, Theme: `headlineSmall` | Ready |
| `add_address_form.dart` | 2+ | `formFieldLabel`, `hintText` | Ready |
| `quote_card.dart` | 2 | `quote`, `smallCapsLabel` | Ready |
| `price_row.dart` | 3 | `priceSmall`, `priceMedium`, `priceLarge` | Ready |
| `rating_chip.dart` | 1 | Theme: `labelSmall` or `statusLabel` | Ready |
| `badge_pill.dart` | 1 | `smallCapsLabel` | Ready |
| **22+ Noto Serif files** | Bulk | (remove font family) | Regex ready |
| **15+ Manrope files** | Bulk | (remove font family) | Regex ready |

---

## Example Patch: Complete Before & After

### File: `ivory_dialog.dart`

**Before:**
```dart
@override
Widget build(BuildContext context) {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        // ... styling
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Noto Serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelLabel,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.outline,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // ... more buttons
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

**After:**
```dart
@override
Widget build(BuildContext context) {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        // ... styling (unchanged)
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dialogTitle,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.dialogMessage,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelLabel,
                    style: AppTextStyles.dialogButton,
                  ),
                ),
                // ... more buttons
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Key Changes:**
- ✅ Removed all inline `TextStyle` constructors
- ✅ Removed all `fontFamily` declarations
- ✅ Code is now 40% shorter
- ✅ Single point of truth for dialog styling
- ✅ Easy to update dialog fonts globally in future

---

## Support & Questions

If you encounter issues while applying patches:

1. **Import Error?** Make sure to import `IvoryTheme` from the theme module
   ```dart
   import 'package:new_flutter/core/theme/theme.dart';
   ```

2. **Color Mismatch?** Check if the style needs color override
   ```dart
   // Use copyWith for color changes:
   style: IvoryTheme.smallCapsLabel.copyWith(
     color: MyCustomColor,
   )
   ```

3. **Size Not Right?** Verify against the consolidated `IvoryTheme` definition in `lib/core/theme/theme.dart`
   - fontSize 10 + bold → `IvoryTheme.smallCapsLabel` or `IvoryTheme.statusLabel`
   - fontSize 14 → `Theme.of(context).textTheme.bodyMedium` or `.labelLarge`
   - fontSize 18+ → `Theme.of(context).textTheme` headline or `IvoryTheme.heroHeading`

---

**Good luck! 🎉 The app will be much more maintainable after these changes.**
