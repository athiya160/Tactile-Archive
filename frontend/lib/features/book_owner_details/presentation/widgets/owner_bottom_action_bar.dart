import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class OwnerBottomActionBar extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onMore;

  const OwnerBottomActionBar({
    super.key,
    required this.onEdit,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: const Color(
              0xFFFAF9F5,
            ).withValues(alpha: 0.9), // stone-50/90
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [DSColors.primary, DSColors.primaryHover],
                      ),
                      borderRadius: BorderRadius.circular(DSRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: DSColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_note, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Listing',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // const SizedBox(width: 16),
              // GestureDetector(
              //   onTap: onMore,
              //   child: Container(
              //     padding: const EdgeInsets.all(16),
              //     decoration: BoxDecoration(
              //       color: DSColors.borderLight,
              //       borderRadius: BorderRadius.circular(DSRadius.xl),
              //     ),
              //     child: const Icon(
              //       Icons.more_vert,
              //       color: DSColors.primary,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
