import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/activity_bloc.dart';
import '../../domain/entities/activity_item.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return BlocListener<ActivityBloc, ActivityState>(
          listener: (context, state) {
            if (state is ActivityError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is ActivityLoaded && state.message != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message!)));
            }
          },
          child: IvoryScaffold(
            showAppBar: false,
            body: _buildBody(context, isDesktop),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, bool isDesktop) {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        if (state is ActivityInitial || state is ActivityLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ActivityError) {
          return Center(child: Text(state.message));
        }

        if (state is ActivityLoaded) {
          final textTheme = Theme.of(context).textTheme;
          return SingleChildScrollView(
            physics: isDesktop
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              DSSpacing.lg,
              DSSpacing.md,
              DSSpacing.lg,
              DSSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editorial Header
                const SizedBox(height: DSSpacing.md),
                Text(
                  'Updates & Interactions'.toUpperCase(),
                  style: IvoryTheme.smallCapsLabel.copyWith(
                    color: DSColors.textLight.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: DSSpacing.sm),
                Text(
                  'Your curated feed of library movements, requests, and reminders across the archive.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: DSColors.textLight,
                  ),
                ),
                const SizedBox(height: DSSpacing.md),
                Column(
                  children: state.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: DSSpacing.lg),
                          child: _buildActivityCard(context, item, state),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: DSSpacing.lg),
                Text(
                  'Archived earlier'.toUpperCase(),
                  style: IvoryTheme.smallCapsLabelXWide,
                ),
                const SizedBox(height: DSSpacing.sm),
                _buildArchivedRow(context),
                const SizedBox(height: DSSpacing.xxl),
                _buildLibrarianTip(context),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    ActivityItem item,
    ActivityLoaded state,
  ) {
    final color = _accentColorForType(item.type);
    final isProcessing = state.processingId == item.id;
    final cardBg = _backgroundColorForType(item.type);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border(
          left: BorderSide(color: color, width: DSSpacing.xs),
        ), // 4px
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DSSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(DSSpacing.sm),
                        decoration: BoxDecoration(
                          color: _iconBackgroundForType(item.type),
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                        ),
                        child: Icon(
                          _iconForType(item.type),
                          color: color,
                          size: DSSpacing.md + DSSpacing.xs, // 20px
                        ),
                      ),
                      const SizedBox(
                        width: DSSpacing.md + DSSpacing.xs,
                      ), // 20px
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: textTheme.headlineSmall),
                            const SizedBox(height: DSSpacing.xs),
                            Text(
                              item.timestamp.toUpperCase(),
                              style: IvoryTheme.statusLabel,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.md),
                  Text(
                    item.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: DSColors.textLight,
                    ),
                  ),
                  if (item.availableActions.isNotEmpty) ...[
                    const SizedBox(height: DSSpacing.lg),
                    Wrap(
                      spacing: DSSpacing.sm,
                      runSpacing: DSSpacing.sm,
                      children: item.availableActions.map((actionType) {
                        return SizedBox(
                          height:
                              DSSpacing.xl +
                              DSSpacing.xs, // 36px Compact py-2 buttons
                          child: _buildActionButton(
                            context,
                            actionType,
                            item.id,
                            isProcessing,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ActivityActionType actionType,
    String activityId,
    bool isProcessing,
  ) {
    final label = _labelForAction(actionType);
    final onPressed = isProcessing
        ? null
        : () {
            switch (actionType) {
              case ActivityActionType.approve:
                context.read<ActivityBloc>().add(
                  ActivityApprovePressed(activityId),
                );
                break;
              case ActivityActionType.deny:
                context.read<ActivityBloc>().add(
                  ActivityDenyPressed(activityId),
                );
                break;
              case ActivityActionType.returnNow:
                context.read<ActivityBloc>().add(
                  ActivityReturnNowPressed(activityId),
                );
                break;
              case ActivityActionType.viewOrder:
                context.push('/order-history');
                break;
            }
          };

    final isPrimary =
        actionType == ActivityActionType.approve ||
        actionType == ActivityActionType.returnNow;

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.primary,
          foregroundColor: DSColors.textInverse,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(DSRadius.lg)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
        ),
        child: Text(label.toUpperCase()),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: DSColors.textDark,
        side: const BorderSide(color: DSColors.borderLight),
        backgroundColor: DSColors.border,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(DSRadius.lg)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
      ),
      child: Text(label.toUpperCase()),
    );
  }

  Widget _buildArchivedRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.md,
      ),
      decoration: BoxDecoration(
        color: DSColors.surface,
        border: Border(
          left: BorderSide(
            color: DSColors.borderLight.withValues(alpha: 0.5),
            width: DSSpacing.xs / 4, // 1px
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_add_outlined,
            color: DSColors.textLight.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: DSSpacing.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Clara Oswald',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DSColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: ' started following your reading list.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: DSColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: DSSpacing.md),
          Text(
            '2D',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: DSColors.textLight.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarianTip(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.xl),
        decoration: BoxDecoration(
          color: const Color(0xFF0D3B2E),
          borderRadius: BorderRadius.circular(DSRadius.lg),
          boxShadow: DSShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories, color: Color(0xFFD69E2E), size: 20),
                const SizedBox(width: DSSpacing.sm),
                Text(
                  'READER COMMUNITY TIP'.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DSColors.textInverse,
                    letterSpacing: 1.5,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.md),
            Text(
              'Returning borrowed books on time earns you Tactile Karma points and unlocks priority reservations for rare archive first editions.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: DSColors.textInverse.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColorForType(ActivityItemType type) {
    switch (type) {
      case ActivityItemType.rentRequest:
        return const Color(0xFF064E3B); // Refined Deep Emerald
      case ActivityItemType.returnOverdue:
        return const Color(0xFF8B3A5D); // tertiary-tone
      case ActivityItemType.favoriteUpdate:
        return const Color(0xFF4A7C59); // emerald-600
      case ActivityItemType.purchaseConfirmation:
        return const Color(0xFF999999); // stone-300
      case ActivityItemType.follower:
        return const Color(0xFF999999); // stone-200
    }
  }

  Color _backgroundColorForType(ActivityItemType type) {
    switch (type) {
      case ActivityItemType.rentRequest:
        return DSColors.surface; // #f4f4f0
      case ActivityItemType.returnOverdue:
        return DSColors.border; // #ffffff
      case ActivityItemType.favoriteUpdate:
        return DSColors.surface; // #f4f4f0
      case ActivityItemType.purchaseConfirmation:
        return DSColors.border; // #ffffff
      case ActivityItemType.follower:
        return DSColors.surface; // #f4f4f0
    }
  }

  Color _iconBackgroundForType(ActivityItemType type) {
    switch (type) {
      case ActivityItemType.rentRequest:
        return const Color(0xFFD0E9D4); // primary-fixed
      case ActivityItemType.returnOverdue:
        return const Color(0xFFFFD9DC); // tertiary-fixed
      case ActivityItemType.favoriteUpdate:
        return const Color(0xFFD0E9D4); // primary-fixed
      case ActivityItemType.purchaseConfirmation:
        return const Color(0xFFD9E2D8); // secondary-container
      case ActivityItemType.follower:
        return const Color(0xFFD9E2D8); // secondary-container
    }
  }

  IconData _iconForType(ActivityItemType type) {
    switch (type) {
      case ActivityItemType.rentRequest:
        return Icons.auto_stories_outlined;
      case ActivityItemType.returnOverdue:
        return Icons.event_busy_outlined;
      case ActivityItemType.favoriteUpdate:
        return Icons.star_outline;
      case ActivityItemType.purchaseConfirmation:
        return Icons.shopping_bag_outlined;
      case ActivityItemType.follower:
        return Icons.person_add_outlined;
    }
  }

  String _labelForAction(ActivityActionType actionType) {
    switch (actionType) {
      case ActivityActionType.approve:
        return 'Approve';
      case ActivityActionType.deny:
        return 'Deny';
      case ActivityActionType.returnNow:
        return 'Return Now';
      case ActivityActionType.viewOrder:
        return 'View Order';
    }
  }
}
