import os

path = r'frontend/lib/features/account_settings/presentation/pages/account_settings_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports if missing
imports_to_add = """import 'package:google_fonts/google_fonts.dart';
import 'package:libri_flow/core/services/api_service.dart';
"""
if 'package:google_fonts/google_fonts.dart' not in content:
    content = imports_to_add + content

# 2. Add sections after Account Settings header
target_marker = """                      Text(
                        'Account Settings',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.xl),"""

replacement_marker = """                      Text(
                        'Account Settings',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.xl),

                  // 🔄 Platform Experience Mode Section
                  _buildPlatformExperienceSection(context),
                  const SizedBox(height: 36),

                  // 🏪 Provider Capabilities Section
                  _buildProviderCapabilitiesSection(context),
                  const SizedBox(height: 36),"""

assert target_marker in content, "target_marker not found in account_settings_page.dart"
content = content.replace(target_marker, replacement_marker)

# 3. Add helper methods before class ends
helper_methods = """
  Widget _buildPlatformExperienceSection(BuildContext context) {
    return ValueListenableBuilder<UserType>(
      valueListenable: ApiService.experienceState,
      builder: (context, activeExp, _) {
        final isStudent = activeExp == UserType.student;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Experience',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: DSSpacing.xs),
            Text(
              'Select how The Tactile Archive adapts to you. All orders, saved items, and account history are seamlessly preserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DSColors.textLight,
                  ),
            ),
            const SizedBox(height: DSSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: DSColors.surface,
                borderRadius: BorderRadius.circular(DSRadius.lg),
                border: Border.all(color: DSColors.borderLight.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  // Student Experience Row
                  InkWell(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
                    onTap: isStudent
                        ? null
                        : () async {
                            final success = await ApiService.switchExperience(UserType.student);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Switched to Student Experience! Academic tools activated.'),
                                  backgroundColor: DSColors.primary,
                                ),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(DSSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isStudent ? DSColors.primary.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              color: isStudent ? DSColors.primary : DSColors.textLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: DSSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Student Experience',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: DSColors.textDark,
                                          ),
                                    ),
                                    if (isStudent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: DSColors.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Optimized for coursework, semester planning, syllabus tools, textbook discovery & AI study.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: DSColors.textLight,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: DSSpacing.sm),
                          Radio<UserType>(
                            value: UserType.student,
                            groupValue: activeExp,
                            activeColor: DSColors.primary,
                            onChanged: (val) async {
                              if (val != null && val != activeExp) {
                                await ApiService.switchExperience(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildDivider(),
                  // Reader Experience Row
                  InkWell(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(DSRadius.lg)),
                    onTap: !isStudent
                        ? null
                        : () async {
                            final success = await ApiService.switchExperience(UserType.reader);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Switched to Reader Experience! Bookshelf & reading goals active.'),
                                  backgroundColor: DSColors.primary,
                                ),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(DSSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: !isStudent ? DSColors.primary.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_stories_outlined,
                              color: !isStudent ? DSColors.primary : DSColors.textLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: DSSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Reader Experience',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: DSColors.textDark,
                                          ),
                                    ),
                                    if (!isStudent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: DSColors.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Focused on personal reading, Living Bookshelf, reading goals, AI concierge & literary discovery.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: DSColors.textLight,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: DSSpacing.sm),
                          Radio<UserType>(
                            value: UserType.reader,
                            groupValue: activeExp,
                            activeColor: DSColors.primary,
                            onChanged: (val) async {
                              if (val != null && val != activeExp) {
                                await ApiService.switchExperience(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProviderCapabilitiesSection(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.providerState,
      builder: (context, enabled, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider Capabilities (Selling & Lending)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: DSSpacing.xs),
            Text(
              'Enable marketplace selling and lending directly on your account. No separate login needed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DSColors.textLight,
                  ),
            ),
            const SizedBox(height: DSSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: DSColors.surface,
                borderRadius: BorderRadius.circular(DSRadius.lg),
                border: Border.all(
                  color: enabled ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : DSColors.borderLight.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(DSSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: enabled ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.storefront_outlined,
                      color: enabled ? const Color(0xFFB45309) : DSColors.textLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              enabled ? 'Provider Mode Active' : 'Provider Mode Inactive',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DSColors.textDark,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: enabled ? const Color(0xFFC6F6D5) : const Color(0xFFEDF2F7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                enabled ? 'ACTIVE' : 'NOT ENROLLED',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: enabled ? const Color(0xFF22543D) : const Color(0xFF4A5568),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          enabled
                              ? 'You can list books for sale, rent out copies, and manage inventory.'
                              : 'Activate provider mode to list and rent books to fellow students and readers.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DSColors.textLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DSSpacing.md),
                  DSButton(
                    text: enabled ? 'Open Hub' : 'Activate',
                    variant: enabled ? DSButtonVariant.secondary : DSButtonVariant.primary,
                    onPressed: () async {
                      if (enabled) {
                        context.push('/provider');
                      } else {
                        final success = await ApiService.activateProvider();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Provider Mode Activated! You can now list books.'),
                              backgroundColor: DSColors.primary,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
"""

last_brace = content.rfind('}')
assert last_brace != -1, "last brace not found"
content = content[:last_brace] + helper_methods + '\n}\n'

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESSFULLY PATCHED account_settings_page.dart!")
