import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/upload_item.dart';
import 'upload_item_card.dart';
import 'curators_tip_card.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class UploadsTab extends StatelessWidget {
  final List<UploadItem> uploads;

  const UploadsTab({super.key, required this.uploads});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Uploads",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: DSColors.primary),
              ),
              _UploadNewButton(),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),
          if (uploads.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DSSpacing.xl),
              decoration: BoxDecoration(
                color: DSColors.surface,
                borderRadius: BorderRadius.circular(DSRadius.lg),
                border: Border.all(
                  color: DSColors.borderLight.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: DSColors.textLight,
                  ),
                  const SizedBox(height: DSSpacing.md),
                  Text(
                    'No Books Uploaded Yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DSColors.primary,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.xs),
                  Text(
                    'Share books from your bookshelf for borrowing, renting, or selling to the community.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DSColors.textLight,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.push('/sell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                      ),
                    ),
                    child: const Text('Add Your First Book'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: uploads.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: DSSpacing.md),
              itemBuilder: (context, index) =>
                  UploadItemCard(upload: uploads[index]),
            ),
          const SizedBox(height: DSSpacing.xxl),
          const CuratorsTipCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _UploadNewButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DSColors.borderLight,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: DSColors.borderLight.withValues(alpha: 1.0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/sell'),
          borderRadius: BorderRadius.circular(DSRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.md,
              vertical: DSSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: DSColors.primary),
                const SizedBox(width: DSSpacing.xs),
                Text(
                  "UPLOAD NEW",
                  style: IvoryTheme.statusLabel.copyWith(
                    color: DSColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
