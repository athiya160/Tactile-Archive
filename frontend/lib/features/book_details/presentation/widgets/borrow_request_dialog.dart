import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import '../../../home/domain/entities/book.dart';

class BorrowRequestDialog extends StatefulWidget {
  final Book book;
  final Function(int days, String message) onSubmit;

  const BorrowRequestDialog({
    super.key,
    required this.book,
    required this.onSubmit,
  });

  @override
  State<BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<BorrowRequestDialog> {
  int _selectedDays = 14;
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    if (mounted) {
      widget.onSubmit(_selectedDays, _messageController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Borrow Request',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DSColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a request to borrow "${widget.book.title}"',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: DSColors.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Duration Selection
                Text(
                  'How many days do you need it for?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DSColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: DSColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DSColors.borderLight),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: DSColors.textLight,
                            ),
                          ),
                          Text(
                            '$_selectedDays Days',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DSColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: DSColors.primary,
                          inactiveTrackColor: DSColors.primary.withValues(alpha: 0.1),
                          thumbColor: DSColors.primary,
                          overlayColor: DSColors.primary.withValues(alpha: 0.2),
                          valueIndicatorColor: DSColors.primary,
                        ),
                        child: Slider(
                          value: _selectedDays.toDouble(),
                          min: 7,
                          max: 30,
                          divisions: 23,
                          label: '$_selectedDays',
                          onChanged: (value) {
                            setState(() {
                              _selectedDays = value.toInt();
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 Week', style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight)),
                          Text('1 Month', style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Request Message
                Text(
                  'Message to the owner',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DSColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'e.g., Hi! I need this for a project next week. Could we meet at the campus library?',
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: DSColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: DSColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: DSColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: DSColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF061B0E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send Borrow Request',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
