import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTestimonials extends StatelessWidget {
  const HomeTestimonials({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDFBF7),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF4EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2D7CD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Testimonials',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D3B2E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"The Tactile Archive helped me find rare academic books and connect with amazing readers in my city!"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF4A5568),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '— Riya, College Student',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D3B2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
