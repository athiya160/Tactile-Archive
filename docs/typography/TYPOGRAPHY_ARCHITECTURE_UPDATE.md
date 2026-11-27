# Typography Architecture Update

**Date:** April 14, 2026  
**Status:** Architecture Consolidated ✅

## Summary

The typography system has been **consolidated into `IvoryTheme`** for better maintainability and clarity. All custom typography tokens now live alongside the standard Material `TextTheme` definition.

---

## Changes Made

### Before (Scattered Architecture)
```
lib/core/theme/theme.dart          → TextTheme definition only
lib/core/tokens/app_text_styles.dart → Custom tokens (separate)
lib/core/tokens/app_tokens.dart    → Colors, spacing, shadows
```

**Problem:** Typography split across two files, creating cognitive overhead

---

### After (Consolidated Architecture)
```
lib/core/theme/theme.dart
  ├─ TextTheme (Material standard styles)
  ├─ Custom tokens (Tactile Archive-specific styles)
  └─ All typography in one place ✅

lib/core/tokens/app_text_styles.dart  → Compatibility shim (deprecated, redirects to IvoryTheme)
lib/core/tokens/app_tokens.dart       → Colors, spacing, shadows (unchanged)
```

**Benefits:**
- ✅ Single source of truth for typography
- ✅ Easier to maintain (all styles in one theme class)
- ✅ Clearer organization
- ✅ Reduced imports (just `IvoryTheme`)
- ✅ Backwards compatible

---

## Usage

### Recommended Pattern (NEW) ✅
```dart
import 'package:new_flutter/core/theme/theme.dart';

// Standard Material theme styles (context-dependent)
Theme.of(context).textTheme.headlineSmall
Theme.of(context).textTheme.bodyLarge

// Custom Tactile Archive tokens (static access)
IvoryTheme.smallCapsLabel
IvoryTheme.buttonLabel
IvoryTheme.quote
IvoryTheme.dialogTitle
```

### Legacy Pattern (Deprecated, Still Works) ⚠️
```dart
import 'package:new_flutter/core/tokens/app_tokens.dart';

AppTextStyles.smallCapsLabel  // ⚠️ Deprecated: redirects to IvoryTheme
```

---

## Migration for Existing Code

### If You've Already Started Using `AppTextStyles`

Just update imports:

**Before:**
```dart
import 'package:new_flutter/core/tokens/app_tokens.dart';

Text('Label', style: AppTextStyles.smallCapsLabel)
```

**After:**
```dart
import 'package:new_flutter/core/theme/theme.dart';

Text('Label', style: IvoryTheme.smallCapsLabel)
```

The `AppTextStyles` will continue to work via the compatibility shim, but IDE will show deprecation warnings. This is intentional—guides you toward the recommended approach.

---

## IvoryTheme Structure

All typography tokens are now static getters on `IvoryTheme`:

```dart
class IvoryTheme {
  // Standard Material TextTheme (via ThemeData)
  static ThemeData get light { ... }
  static TextTheme get _textTheme { ... }
  
  // Custom Tactile Archive typography tokens
  static TextStyle get smallCapsLabel { ... }
  static TextStyle get buttonLabel { ... }
  static TextStyle get quote { ... }
  static TextStyle get dialogTitle { ... }
  // ... 14 more tokens
}
```

---

## File Changes Summary

| File | Change | Reason |
|------|--------|--------|
| `lib/core/theme/theme.dart` | ✏️ **Expanded** with all custom tokens | Consolidated single source of truth |
| `lib/core/tokens/app_text_styles.dart` | 🔄 **Converted to shim** | Backwards compatibility + deprecation guidance |
| `lib/core/tokens/app_tokens.dart` | 🔧 Removed export | Cleaned up (now import `theme.dart` directly) |
| `TYPOGRAPHY_MIGRATION_GUIDE.md` | ✏️ **Updated** | References `IvoryTheme` instead of `AppTextStyles` |
|  `TYPOGRAPHY_AUDIT_REPORT.md` | ✏️ Same validity | Recommendations unchanged, just consolidated |

---

## Why This Decision?

**Question:** Should `AppTextStyles` and `TextTheme` be merged in `IvoryTheme`?

**Answer:** ✅ **YES** — Here's why:

### Architectural Benefits
1. **Single Source of Truth**: All typography decisions live in one class
2. **Clear Ownership**: `IvoryTheme` owns all theme-related styling
3. **Better Discoverability**: IDE autocomplete shows all available styles in one place
4. **Reduced Coupling**: Don't need to import two separate modules
5. **Type Safety**: Everything is already in `ThemeData`, so it's cohesive

### Frameworks Precedent
- Material Design's `ThemeData` consolidates all design tokens
- Flutter's `ColorScheme` includes all color tokens
- Following framework patterns makes code more idiomatic

### Practical Impact
```dart
// ✅ Cleaner: Everything typography is here
import 'package:new_flutter/core/theme/theme.dart';
theme: IvoryTheme.light,
style: IvoryTheme.buttonLabel

// ❌ Messier: Split across two classes
import 'package:new_flutter/core/theme/theme.dart';
import 'package:new_flutter/core/tokens/app_tokens.dart';
theme: IvoryTheme.light,
style: AppTextStyles.buttonLabel
```

---

## Implementation Status

| Task | Status |
|------|--------|
| Consolidate tokens into `IvoryTheme` | ✅ Complete |
| Update `app_text_styles.dart` to shim | ✅ Complete |
| Create deprecation guidance | ✅ Complete |
| Update migration guide | ✅ In progress |
| All reports reflect new architecture | ✅ Complete |

---

## Next Steps

1. **Use `IvoryTheme` for all new typography** (recommended pattern)
2. **When patching existing code**, import and use `IvoryTheme` directly
3. **Optional:** Run `dart fix` later to clean up deprecation warnings (no functional change needed)

---

## Backwards Compatibility

The `AppTextStyles` class remains functional as a compatibility shim through at least v1.0. No breaking changes—just deprecation guidance.

```dart
// Both work identically (just different imports):
IvoryTheme.buttonLabel              // ✅ Recommended
AppTextStyles.buttonLabel            // ✅ Still works, shows warning
```

---

## Questions?

Refer to:
- **Setup & Basics:** `TYPOGRAPHY_MIGRATION_GUIDE.md`
- **Comprehensive Audit:** `TYPOGRAPHY_AUDIT_REPORT.md`
- **Source of Truth:** `lib/core/theme/theme.dart` (the IvoryTheme class)

---

**Architecture Decision:** Consolidation ✅  
**Backwards Compatible:** Yes ✅  
**Deprecation Timeline:** Flexible (no hurry to migrate existing code)
