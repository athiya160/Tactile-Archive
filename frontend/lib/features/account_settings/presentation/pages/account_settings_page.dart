import 'package:google_fonts/google_fonts.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/features/account_settings/presentation/bloc/settings_bloc.dart';
import 'package:libri_flow/features/account_settings/presentation/widgets/notification_toggle_row.dart';
import 'package:libri_flow/features/account_settings/presentation/widgets/profile_avatar_upload.dart';
import 'package:libri_flow/features/account_settings/presentation/widgets/settings_input_field.dart';
import 'package:libri_flow/features/account_settings/presentation/widgets/change_password_dialog.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DSColors.background,
      body: SafeArea(
        child: AccountSettingsView(),
      ),
    );
  }
}

class AccountSettingsView extends StatelessWidget {
  const AccountSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.status == SettingsStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? 'Success'),
              backgroundColor: DSColors.primary,
            ),
          );
        } else if (state.status == SettingsStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error'),
              backgroundColor: DSColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == SettingsStatus.loading &&
            state.initialSettings == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = state.currentSettings ??
            state.initialSettings ??
            SettingsBloc.defaultSettings;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: DSSpacing.lg,
              right: DSSpacing.lg,
              bottom: DSSpacing.xl,
            ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: DSColors.textDark,
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/profile');
                          }
                        },
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Text(
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
                  const SizedBox(height: 36),
                  // Personal Profile Section
                  Text(
                    'Personal Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: DSSpacing.xl),
                  Center(
                    child: ProfileAvatarUpload(
                      avatarUrl: settings.avatarUrl,
                      onEditPressed: (imageSource) {
                        context.read<SettingsBloc>().add(
                          AvatarUploadPressed(imageSource),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: DSSpacing.xl),
                  _buildInputFields(context, settings),
                  const SizedBox(height: 48),

                  // Security Settings Section
                  Text(
                    'Security Settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: DSSpacing.sm),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: DSColors.borderLight.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: DSSpacing.lg),
                  Container(
                    decoration: BoxDecoration(
                      color: DSColors.surface,
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                      border: Border.all(color: DSColors.borderLight.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.all(DSSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: DSColors.textDark,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update your password to keep your account secure.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DSColors.textLight,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        DSButton(
                          text: 'Change',
                          variant: DSButtonVariant.secondary,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: context.read<SettingsBloc>(),
                                child: const ChangePasswordDialog(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Notification Preferences Section
                  Text(
                    'Notification Preferences',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: DSSpacing.sm),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: DSColors.borderLight.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: DSSpacing.lg),
                  _buildNotificationToggles(context, settings),
                  const SizedBox(height: DSSpacing.xxl),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: DSButton(
                      text: state.status == SettingsStatus.loading
                          ? 'Updating...'
                          : 'Update Settings',
                      onPressed: state.status == SettingsStatus.loading
                          ? null
                          : () => context.read<SettingsBloc>().add(
                              SettingsSavePressed(),
                            ),
                    ),
                  ),
                  const SizedBox(height: DSSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: DSButton(
                      text: 'Discard Changes',
                      variant: DSButtonVariant.secondary,
                      onPressed: state.status == SettingsStatus.loading
                          ? null
                          : () => context.read<SettingsBloc>().add(
                              SettingsDiscardPressed(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ⚠️ Danger Zone / Account Deletion Section
                  _buildDangerZoneSection(context),
                ],
              ),
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildInputFields(BuildContext context, dynamic settings) {
    return Column(
      children: [
        SettingsInputField(
          label: 'Full Name',
          initialValue: settings.fullName,
          onChanged: (val) => context.read<SettingsBloc>().add(
            SettingsFieldChanged(fullName: val),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        SettingsInputField(
          label: 'Email Address',
          initialValue: settings.email,
          onChanged: (val) => context.read<SettingsBloc>().add(
            SettingsFieldChanged(email: val),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        SettingsInputField(
          label: 'Phone Number',
          initialValue: settings.phone,
          onChanged: (val) => context.read<SettingsBloc>().add(
            SettingsFieldChanged(phone: val),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        SettingsInputField(
          label: 'Mailing Address',
          initialValue: settings.address,
          onChanged: (val) => context.read<SettingsBloc>().add(
            SettingsFieldChanged(address: val),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        SettingsInputField(
          label: 'Personal Bio',
          initialValue: settings.bio,
          isMultiline: true,
          onChanged: (val) =>
              context.read<SettingsBloc>().add(SettingsFieldChanged(bio: val)),
        ),
      ],
    );
  }

  Widget _buildNotificationToggles(BuildContext context, dynamic settings) {
    return Container(
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: DSColors.borderLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          NotificationToggleRow(
            title: 'Rent Request',
            subtitle: 'Notify me when someone wants to borrow my books',
            value: settings.notifications['Rent Request'] ?? false,
            onChanged: (val) => context.read<SettingsBloc>().add(
              SettingsToggleChanged('Rent Request', val),
            ),
          ),
          _buildDivider(),
          NotificationToggleRow(
            title: 'Purchase Request',
            subtitle: 'Notify me when someone makes an offer to buy',
            value: settings.notifications['Purchase Request'] ?? false,
            onChanged: (val) => context.read<SettingsBloc>().add(
              SettingsToggleChanged('Purchase Request', val),
            ),
          ),
          _buildDivider(),
          NotificationToggleRow(
            title: 'New Book Arrival',
            subtitle: 'Alerts for books matching my wishlist criteria',
            value: settings.notifications['New Book Arrival'] ?? false,
            onChanged: (val) => context.read<SettingsBloc>().add(
              SettingsToggleChanged('New Book Arrival', val),
            ),
          ),
          _buildDivider(),
          NotificationToggleRow(
            title: 'Book Due Reminders',
            subtitle: 'Reminders for upcoming return deadlines',
            value: settings.notifications['Book Due Reminders'] ?? false,
            onChanged: (val) => context.read<SettingsBloc>().add(
              SettingsToggleChanged('Book Due Reminders', val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
      color: DSColors.borderLight.withValues(alpha: 0.1),
    );
  }

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

  Widget _buildDangerZoneSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFFDC2626),
              ),
        ),
        const SizedBox(height: DSSpacing.xs),
        Text(
          'Actions here are irreversible. Please proceed with caution.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DSColors.textLight,
              ),
        ),
        const SizedBox(height: DSSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(
              color: const Color(0xFFFCA5A5),
            ),
          ),
          padding: const EdgeInsets.all(DSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Text(
                    'Delete Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF991B1B),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.sm),
              Text(
                'Permanently close your account, purge your profile, saved addresses, reading goals, and cart. Active provider book listings will be delisted immediately.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7F1D1D),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: DSSpacing.xs),
              Text(
                '• Note: Active rentals or unfulfilled orders must be completed first.\n• Historical financial records will be retained in anonymized form for statutory tax and audit compliance.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF991B1B),
                      fontSize: 11,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: DSSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DSRadius.md),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.delete_forever, size: 20),
                  label: Text(
                    'Delete Account',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _showDeleteAccountConfirmationDialog(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isSubmitting = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFDC2626),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confirm Deletion',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF061B0E),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Are you absolutely sure? This action is permanent and cannot be undone.\n\n'
                      'To protect your security, please verify your identity by entering your password or typing DELETE below.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5568),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password or type "DELETE"',
                        hintText: 'Enter your password or DELETE',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: localError,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    if (isSubmitting) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4A5568),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final input = passwordController.text.trim();
                          if (input.isEmpty) {
                            setDialogState(() {
                              localError = 'Please enter your password or type DELETE.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            localError = null;
                          });

                          final res = await ApiService.deleteAccount(
                            password: input,
                            confirmation: input,
                          );

                          if (res['success'] == true) {
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account successfully deleted. All personal data has been erased.'),
                                  backgroundColor: Color(0xFF061B0E),
                                ),
                              );
                              context.go('/login');
                            }
                          } else {
                            setDialogState(() {
                              isSubmitting = false;
                              localError = res['error'] ?? 'Failed to delete account.';
                            });
                          }
                        },
                  child: Text(
                    'Permanently Delete',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
