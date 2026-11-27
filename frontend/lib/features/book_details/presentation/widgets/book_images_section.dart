import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/domain/entities/book.dart';

class BookImagesSection extends StatefulWidget {
  final Book book;

  const BookImagesSection({super.key, required this.book});

  @override
  State<BookImagesSection> createState() => _BookImagesSectionState();
}

class _BookImagesSectionState extends State<BookImagesSection> {
  int _activeIndex = 0;

  final List<String> _sampleGallery = [
    'https://images-na.ssl-images-amazon.com/images/I/81zE42gT3xL.jpg', // Brave New World
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400',   // Open book pages
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400',   // Book stack
    'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=400',   // Reading nook
  ];

  @override
  Widget build(BuildContext context) {
    final coverUrl = widget.book.coverUrl.isNotEmpty ? widget.book.coverUrl : _sampleGallery[0];
    final gallery = [coverUrl, ..._sampleGallery.sublist(1)];

    return Material(
      color: Colors.transparent,
      child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAIN COVER IMAGE PREVIEW (LARGE)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: gallery[_activeIndex].startsWith('assets/')
                      ? Image.asset(
                          gallery[_activeIndex],
                          height: 400,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildCoverFallback(400),
                        )
                      : Image.network(
                          gallery[_activeIndex],
                          height: 400,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildCoverFallback(400),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // VERTICAL THUMBNAIL STRIP
            Column(
              children: List.generate(gallery.length, (idx) {
                final isSelected = _activeIndex == idx;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _activeIndex = idx),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: 58,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: gallery[idx].startsWith('assets/')
                              ? Image.asset(
                                  gallery[idx],
                                  width: 58,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.menu_book, size: 16, color: Color(0xFF718096)),
                                  ),
                                )
                              : Image.network(
                                  gallery[idx],
                                  width: 58,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.menu_book, size: 16, color: Color(0xFF718096)),
                                  ),
                                ),
                        ),
                        if (idx == 3)
                          Container(
                            width: 58,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Center(
                              child: Text(
                                '+6',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // "PREVIEW INSIDE" FULL-WIDTH BUTTON
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening interactive sample chapter preview...')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D3B2E),
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.auto_stories_outlined, size: 16),
            label: Text(
              'Preview Inside',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildCoverFallback(double height) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F3EA), Color(0xFFEFE6D6)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              ),
              child: const FaIcon(FontAwesomeIcons.bookOpen, size: 40, color: Color(0xFFB8860B)),
            ),
            const SizedBox(height: 12),
            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E2320),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.book.author,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
