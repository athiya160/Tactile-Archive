import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/tokens/app_tokens.dart';

class ModernImageUploader extends StatefulWidget {
  final List<XFile> images;
  final ValueChanged<List<XFile>> onImagesChanged;

  const ModernImageUploader({
    super.key,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  State<ModernImageUploader> createState() => _ModernImageUploaderState();
}

class _ModernImageUploaderState extends State<ModernImageUploader> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> newImages = await _picker.pickMultiImage();
      if (newImages.isNotEmpty) {
        final currentImages = List<XFile>.from(widget.images);
        currentImages.addAll(newImages);
        // Limit to 10
        if (currentImages.length > 10) {
          currentImages.removeRange(10, currentImages.length);
        }
        widget.onImagesChanged(currentImages);
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index) {
    final currentImages = List<XFile>.from(widget.images);
    currentImages.removeAt(index);
    widget.onImagesChanged(currentImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Book Images',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${widget.images.length} / 10',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: widget.images.length == 10 ? Colors.red : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'First image will be used as the cover. High quality images increase sales.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        MouseRegion(
          cursor: widget.images.length < 10 ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTap: widget.images.length < 10 ? _pickImages : null,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 2,
                  style: BorderStyle.solid, // Using solid as flutter doesn't support dashed borders natively without a package
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.cloudArrowUp,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Click to upload or drag and drop',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SVG, PNG, JPG or WEBP (max. 10MB)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.images.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(widget.images.length, (index) {
              final isCover = index == 0;
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCover ? AppColors.tertiary : AppColors.outline.withOpacity(0.2),
                    width: isCover ? 2 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      // Mocking preview since XFile preview on web requires FutureBuilder
                      child: Container(
                        color: AppColors.surfaceContainerHighest,
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (isCover)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            'COVER',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
