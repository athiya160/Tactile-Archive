import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class CategoryChipGroup extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChipGroup({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT CATEGORY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DSColors.textLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: DSSpacing.md),
        Wrap(
          spacing: DSSpacing.sm,
          runSpacing: DSSpacing.sm,
          children: categories.map((category) {
            final isSelected = category == selectedCategory;
            return ChoiceChip(
              label: Text(category.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onSelected(category),
              selectedColor: DSColors.primary,
              backgroundColor: DSColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? DSColors.textInverse : DSColors.textDark,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100.0),
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
