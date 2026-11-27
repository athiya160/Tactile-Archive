import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libri_flow/core/services/api_service.dart';

class DamageInspectionScreen extends StatefulWidget {
  const DamageInspectionScreen({super.key});

  @override
  State<DamageInspectionScreen> createState() => _DamageInspectionScreenState();
}

class _DamageInspectionScreenState extends State<DamageInspectionScreen> {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Uint8List? _beforeBytes;
  String? _beforeFilename;
  Uint8List? _afterBytes;
  String? _afterFilename;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhoto(bool isBefore) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBefore ? 'Select Before-Rental Photo' : 'Select After-Return Photo',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D3B2E)),
                title: Text('Take Photo with Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setState(() {
                      if (isBefore) {
                        _beforeBytes = bytes;
                        _beforeFilename = file.name;
                      } else {
                        _afterBytes = bytes;
                        _afterFilename = file.name;
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFC85A32)),
                title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setState(() {
                      if (isBefore) {
                        _beforeBytes = bytes;
                        _beforeFilename = file.name;
                      } else {
                        _afterBytes = bytes;
                        _afterFilename = file.name;
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runAIDamageCheck() async {
    if (_beforeBytes == null && _afterBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload at least one photo (before or after) to analyze condition.'),
          backgroundColor: const Color(0xFFC85A32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final res = await ApiService.inspectBookDamage(
        beforeBytes: _beforeBytes,
        beforeFilename: _beforeFilename,
        afterBytes: _afterBytes,
        afterFilename: _afterFilename,
      );
      if (mounted) {
        setState(() {
          _analysisResult = res;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B2E),
        foregroundColor: Colors.white,
        title: Text('AI Book Damage Inspector', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automated Condition & Deposit Checker',
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0D3B2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload photos of book cover and pages before and after rental. AI Vision calculates condition score & deposit claims.',
              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF4A5568)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoUploadCard(
                    title: 'Before Rental',
                    bytes: _beforeBytes,
                    isBefore: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildPhotoUploadCard(
                    title: 'After Return',
                    bytes: _afterBytes,
                    isBefore: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _runAIDamageCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC85A32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const FaIcon(FontAwesomeIcons.robot, size: 18),
                label: Text(
                  _isAnalyzing ? 'Analyzing Book Condition...' : 'Run AI Condition Analysis',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_isAnalyzing)
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFFC85A32)),
              ))
            else if (_analysisResult != null)
              _buildResultCard(_analysisResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadCard({
    required String title,
    required Uint8List? bytes,
    required bool isBefore,
  }) {
    return InkWell(
      onTap: () => _pickPhoto(isBefore),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: bytes != null ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
            width: bytes != null ? 1.8 : 1,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: bytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    Container(color: Colors.black26),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D3B2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          title,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7F4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_a_photo_outlined, size: 28, color: const Color(0xFF0D3B2E)),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748))),
                  const SizedBox(height: 4),
                  Text('Tap to capture', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> res) {
    final score = res['condition_score'] ?? 96;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Condition Rating', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text('$score% Intact', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.green.shade800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(res['recommendation'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2D3748))),
          const SizedBox(height: 16),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deposit Refund Percent', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
              Text('${res['deposit_refund_percent'] ?? 100}%', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
