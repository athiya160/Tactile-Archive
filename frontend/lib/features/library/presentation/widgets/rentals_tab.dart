import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/rental_item.dart';
import 'rental_item_card.dart';
import 'curators_tip_card.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class RentalsTab extends StatelessWidget {
  final List<RentalItem> rentals;

  const RentalsTab({super.key, required this.rentals});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  Expanded(
                    child: Text(
                      "Active Rentals",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: DSColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Text(
                    "${rentals.length} BOOKS",
                    style: IvoryTheme.statusLabel.copyWith(
                      color: DSColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.lg),
              if (rentals.isEmpty)
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
                        Icons.auto_stories_outlined,
                        size: 48,
                        color: DSColors.textLight,
                      ),
                      const SizedBox(height: DSSpacing.md),
                      Text(
                        'No Active Rentals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DSColors.primary,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.xs),
                      Text(
                        'Explore the archive to rent or borrow physical editions from fellow readers.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DSColors.textLight,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.lg),
                      ElevatedButton(
                        onPressed: () => context.push('/browse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DSRadius.sm),
                          ),
                        ),
                        child: const Text('Browse Archive'),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rentals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: DSSpacing.md),
                  itemBuilder: (context, index) =>
                      RentalItemCard(rental: rentals[index]),
                ),
              const SizedBox(height: DSSpacing.xxl),
              const CuratorsTipCard(),
              const SizedBox(height: 120), // Generous clearance for bottom nav bar and floating action chatbot
            ],
          ),
        );
      },
    );
  }
}
