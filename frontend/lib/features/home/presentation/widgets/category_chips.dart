import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: DSSpacing.sm),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => onSelected(category),
              backgroundColor: DSColors.borderLight,
              selectedColor: DSColors.primary,
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? DSColors.textInverse : DSColors.textLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DSRadius.xl),
                side: BorderSide.none,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.sm,
                vertical: DSSpacing.xs,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
