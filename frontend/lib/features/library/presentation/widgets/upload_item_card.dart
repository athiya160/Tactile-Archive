import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../../../core/widgets/ivory_dialog.dart';
import '../../domain/entities/upload_item.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class UploadItemCard extends StatelessWidget {
  final UploadItem upload;

  const UploadItemCard({super.key, required this.upload});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/book/${upload.id}/owner'),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: Border.all(
            color: DSColors.borderLight.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Placeholder or Image
            ClipRRect(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              child: SizedBox(
                width: 64,
                height: 80,
                child: BookCoverImage(
                  url: upload.coverUrl ?? '',
                  width: 64,
                  height: 80,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                ),
              ),
            ),
            const SizedBox(width: DSSpacing.md),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildTextInfo(context),
                  const SizedBox(height: DSSpacing.md),
                  // Status Chip
                  _StatusChip(status: upload.status),
                ],
              ),
            ),
            const SizedBox(width: DSSpacing.sm),
            // Actions
            Column(
              children: [
                IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete, size: 20),
                  color: DSColors.error.withValues(alpha: 0.7),
                  onPressed: () {
                    IvoryDialog.show(
                      context,
                      title: 'Delete Listing',
                      message:
                          'Are you sure you want to permanently delete "${upload.title}"? This action cannot be undone.',
                      confirmLabel: 'DELETE',
                      isDestructive: true,
                      onConfirm: () {
                        context.read<LibraryBloc>().add(
                          LibraryDeleteUpload(upload.id),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTextInfo(BuildContext context) {
    return [
      Text(
        upload.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: DSColors.primary,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        upload.author,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: DSColors.textLight,
        ),
      ),
    ];
  }
}

class _StatusChip extends StatelessWidget {
  final UploadStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == UploadStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isActive ? DSColors.primary : DSColors.borderLight,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: isActive
            ? null
            : Border.all(color: DSColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Text(
        isActive ? "ACTIVE LISTING" : "PENDING REVIEW",
        style: IvoryTheme.statusLabel.copyWith(
          color: isActive ? DSColors.textInverse : DSColors.border,
        ),
      ),
    );
  }
}
