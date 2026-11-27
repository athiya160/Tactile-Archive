import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  Future<void> _launchEmailSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'athiya160@gmail.com',
      queryParameters: {
        'subject': 'LibriFlow Support Request',
        'body': 'Hi LibriFlow Team,\n\nI need assistance with: ',
      },
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch email app: $e');
    }
  }

  Future<void> _launchPhoneSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+919986474220');
    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch phone app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DSSpacing.xl),
          Text(
            'Direct Support & Concierge',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(
              color: DSColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reach our dedicated team directly via phone, email, or send a detailed ticket.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: DSColors.textLight),
          ),
          const SizedBox(height: DSSpacing.lg),
          _ContactItem(
            icon: Icons.phone_in_talk_outlined,
            title: 'Call Support (+91 99864 74220)',
            subtitle: 'Mon - Sat: 9:00 AM - 6:00 PM',
            onTap: _launchPhoneSupport,
          ),
          const SizedBox(height: DSSpacing.sm),
          _ContactItem(
            icon: Icons.mail_outline,
            title: 'Email Us (athiya160@gmail.com)',
            subtitle: 'Direct support inbox • Replies within 2 hours',
            onTap: _launchEmailSupport,
          ),
          const SizedBox(height: DSSpacing.sm),
          _ContactItem(
            icon: Icons.edit_note_outlined,
            title: 'Send a Message / Complaint',
            subtitle: 'Submit an inquiry or complaint directly to management',
            onTap: () => context.push('/contact'),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DSRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: Border.all(color: DSColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DSColors.borderLight,
                borderRadius: BorderRadius.circular(DSRadius.md),
              ),
              child: Icon(icon, color: DSColors.primary, size: 22),
            ),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DSColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: DSColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: DSColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
