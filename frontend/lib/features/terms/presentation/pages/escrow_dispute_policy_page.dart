import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EscrowDisputePolicyPage extends StatelessWidget {
  const EscrowDisputePolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B2E),
        foregroundColor: Colors.white,
        title: Text('Escrow & Rental Dispute Policy', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LibriFlow Escrow & Deposit Rules', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D3B2E))),
            const SizedBox(height: 12),
            Text('Last Updated: September 2026', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            _buildSection(
              '1. Transaction Escrow Protection',
              'All rental fees and security deposits are held securely in Razorpay Escrow until physical book handoff is verified at a Safe Exchange Hub via QR Code scan.',
            ),
            _buildSection(
              '2. Rental Duration & Returns',
              'Standard peer-to-peer loan duration is 14 calendar days. Late returns accrue a fee of \$0.50/day. Extensions must be requested 48 hours prior to return deadline.',
            ),
            _buildSection(
              '3. Book Damage & Deposit Deductions',
              'If a returned book shows uninspected damage (water spills, missing pages, highlights), the lender may submit photos to the AI Damage Inspector within 48 hours to claim security deposit deductions.',
            ),
            _buildSection(
              '4. Dispute Resolution Process',
              'In case of unverified handoffs or missing returns, LibriFlow Support reviews CCTV logs & QR timestamps. Resolved claims result in deposit release to the aggrieved party.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFC85A32))),
          const SizedBox(height: 6),
          Text(content, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2D3748), height: 1.5)),
        ],
      ),
    );
  }
}
