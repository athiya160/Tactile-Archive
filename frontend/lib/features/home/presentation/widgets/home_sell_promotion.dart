import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/utils/auth_guard.dart';

class HomeSellPromotion extends StatelessWidget {
  const HomeSellPromotion({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 16, bottom: 48), // 1rem 0 3rem
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _buildContainer(context),
        ),
      ),
    );
  }

  Widget _buildContainer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 56,
      ), // 3.5rem 2rem
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3D2E), Color(0xFF145A42)], // #0B3D2E to #145a42
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24), // var(--radius-xl)
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000), // shadow-md approx 0.12
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Got books you no longer use?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Playfair Display',
              fontSize: 32, // 2rem
            ),
          ),
          const SizedBox(height: 12), // margin-bottom: 0.75rem
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Sell them and earn money while helping another reader discover their next favorite book.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16, // 1rem
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 24), // margin-bottom: 1.5rem
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300), // transition
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ), // 0.75rem 1.5rem
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37), // var(--secondary-color)
                  borderRadius: BorderRadius.circular(8), // var(--radius-md)
                ),
                child: const Text(
                  'Sell a Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16, // 1rem
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
