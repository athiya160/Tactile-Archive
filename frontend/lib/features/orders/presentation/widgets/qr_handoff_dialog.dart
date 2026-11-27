import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libri_flow/core/services/api_service.dart';

class QRHandoffDialog extends StatefulWidget {
  final int orderId;

  const QRHandoffDialog({super.key, required this.orderId});

  static Future<void> show(BuildContext context, {required int orderId}) {
    return showDialog(
      context: context,
      builder: (context) => QRHandoffDialog(orderId: orderId),
    );
  }

  @override
  State<QRHandoffDialog> createState() => _QRHandoffDialogState();
}

class _QRHandoffDialogState extends State<QRHandoffDialog> {
  bool _isLoading = true;
  String _qrToken = "BORROWER-101-9A8B7C6D";
  String _role = "borrower";
  bool _escrowReleased = false;

  @override
  void initState() {
    super.initState();
    _loadQRCode();
  }

  Future<void> _loadQRCode() async {
    try {
      final res = await ApiService.get('/orders/${widget.orderId}/qr-code');
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          _qrToken = res.data['qr_token'] ?? _qrToken;
          _role = res.data['role'] ?? _role;
          _escrowReleased = res.data['escrow_released'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyHandoff() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('/orders/${widget.orderId}/verify-qr', data: {
        "qr_token": _qrToken,
        "role": _role,
      });

      if (res.statusCode == 200) {
        setState(() {
          _escrowReleased = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Escrow funds auto-released! Physical handoff verified.'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'QR Escrow Handoff',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFFC85A32)),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.qrcode, size: 96, color: Color(0xFF0D3B2E)),
                            const SizedBox(height: 8),
                            Text(
                              _qrToken.length > 18 ? _qrToken.substring(0, 18) : _qrToken,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _escrowReleased
                          ? '✅ Escrow Payment Released'
                          : 'Show this single-use QR to the safe hub scanner or lender to unlock escrow payout.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: _escrowReleased ? FontWeight.w800 : FontWeight.w500,
                        color: _escrowReleased ? const Color(0xFF27AE60) : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _escrowReleased ? null : _verifyHandoff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _escrowReleased ? Colors.grey : const Color(0xFFC85A32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.shieldHalved, size: 16),
                  label: Text(
                    _escrowReleased ? 'Handoff Verified' : 'Simulate Hub Scan Verification',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
