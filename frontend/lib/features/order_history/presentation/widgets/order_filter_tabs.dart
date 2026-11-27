import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class OrderFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const OrderFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.xs),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      child: Row(
        children: [
          _FilterButton(
            label: 'All History',
            isSelected: selectedFilter == 'All History',
            onTap: () => onFilterChanged('All History'),
          ),
          _FilterButton(
            label: 'Pending',
            isSelected: selectedFilter == 'Pending',
            onTap: () => onFilterChanged('Pending'),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? DSColors.border : Colors.transparent,
            borderRadius: BorderRadius.circular(6), // rounded-md per spec
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? DSColors.primary : DSColors.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
