import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/tokens/app_tokens.dart';

class ConditionSelector extends StatelessWidget {
  final String selectedCondition;
  final ValueChanged<String> onChanged;

  const ConditionSelector({
    super.key,
    required this.selectedCondition,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final conditions = [
      {'title': 'Like New', 'desc': 'Unused, perfect'},
      {'title': 'Excellent', 'desc': 'Minor wear'},
      {'title': 'Good', 'desc': 'Read, well kept'},
      {'title': 'Fair', 'desc': 'Visible wear'},
      {'title': 'Poor', 'desc': 'Heavily worn'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book Condition',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: conditions.map((c) {
            final isSelected = selectedCondition == c['title'];
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged(c['title']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.outline.withOpacity(0.2),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c['title']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.5) : AppColors.outline.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c['desc']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
