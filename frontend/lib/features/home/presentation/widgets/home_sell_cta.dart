import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/utils/auth_guard.dart';

class HomeSellCta extends StatelessWidget {
  const HomeSellCta({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0D697), // Warm premium accent color
      padding: const EdgeInsets.symmetric(
        vertical: 80,
        horizontal: DSSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Give Your Books a Second Life',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: DSColors.primary,
                  letterSpacing: -1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DSSpacing.lg),
              Text(
                'Upload books you no longer use and help other readers while earning money.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DSColors.primary.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ApiService.isLoggedIn) {
                      context.push('/sell');
                    } else {
                      final ok = await requireAuth(
                        context,
                        reason: 'Sign in to sell your book.',
                      );
                      if (ok && context.mounted) context.push('/sell');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.primary,
                    foregroundColor: DSColors.textInverse,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                    ),
                  ),
                  child: const Text(
                    'Sell Your Book',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
