import 'package:flutter/material.dart';
import '../../domain/entities/address.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class AddressRadioCard extends StatelessWidget {
  final Address address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AddressRadioCard({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(DSSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? DSColors.border : DSColors.surface,
          borderRadius: BorderRadius.circular(DSRadius.xl),
          border: Border.all(
            color: isSelected
                ? DSColors.primary
                : const Color(0xFFC3C8C1).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected ? DSShadows.md : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Badge + Custom Radio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.recipientName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: DSColors.primary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: DSSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DSColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DSRadius.sm),
                          ),
                          child: Text(
                            'PRIMARY',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.primary,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (onEdit != null) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: DSColors.primary,
                        ),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: DSSpacing.md),
                    ],
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: DSColors.error,
                        ),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: DSSpacing.md),
                    // Custom Dot-in-Circle Radio
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? DSColors.primary
                              : const Color(0xFFC3C8C1),
                          width: 1,
                        ),
                        color: isSelected
                            ? DSColors.primary
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.md),
            // Address Details
            Text(
              '${address.street}\n${address.city}, ${address.state} - ${address.zipCode}\nIndia',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DSColors.textLight,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: DSSpacing.md),
            // Footer: Phone Info
            Row(
              children: [
                const Icon(Icons.call, size: 16, color: DSColors.textLight),
                const SizedBox(width: DSSpacing.sm),
                Text(
                  address.phoneNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DSColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
