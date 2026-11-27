import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/tokens/app_tokens.dart';

class ListingTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const ListingTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Type',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                title: 'Sell',
                description: 'Sell permanently',
                icon: FontAwesomeIcons.tag,
                isSelected: selectedType == 'Sell',
                onTap: () => onChanged('Sell'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TypeCard(
                title: 'Rent',
                description: 'Rent for a period',
                icon: FontAwesomeIcons.clock,
                isSelected: selectedType == 'Rent',
                onTap: () => onChanged('Rent'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TypeCard(
                title: 'Borrow',
                description: 'Lend for free',
                icon: FontAwesomeIcons.handHoldingHeart,
                isSelected: selectedType == 'Borrow',
                onTap: () => onChanged('Borrow'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String description;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.tertiary : AppColors.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.tertiary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FaIcon(
                    icon,
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  if (isSelected)
                    const FaIcon(
                      FontAwesomeIcons.circleCheck,
                      color: AppColors.tertiary,
                      size: 16,
                    )
                  else
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.outline.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
