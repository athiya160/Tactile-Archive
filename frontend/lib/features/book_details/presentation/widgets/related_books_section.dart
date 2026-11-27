import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/domain/entities/book.dart';

class RelatedBooksSection extends StatefulWidget {
  final List<Book> books;

  const RelatedBooksSection({super.key, required this.books});

  @override
  State<RelatedBooksSection> createState() => _RelatedBooksSectionState();
}

class _RelatedBooksSectionState extends State<RelatedBooksSection> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _sampleRecommendations = [
    {
      'title': '1984',
      'author': 'George Orwell',
      'cover': 'https://images-na.ssl-images-amazon.com/images/I/71kxa1-0mfL.jpg',
      'rating': '★ 4.7',
      'price': '₹399',
    },
    {
      'title': 'Fahrenheit 451',
      'author': 'Ray Bradbury',
      'cover': 'https://images-na.ssl-images-amazon.com/images/I/61z+n5R9Q+L.jpg',
      'rating': '★ 4.5',
      'price': '₹299',
    },
    {
      'title': 'The Handmaid\'s Tale',
      'author': 'Margaret Atwood',
      'cover': 'https://images-na.ssl-images-amazon.com/images/I/61tG6uU6HhL.jpg',
      'rating': '★ 4.6',
      'price': '₹450',
    },
    {
      'title': 'The Catcher in the Rye',
      'author': 'J.D. Salinger',
      'cover': 'https://images-na.ssl-images-amazon.com/images/I/81OthjkJBuL.jpg',
      'rating': '★ 4.4',
      'price': '₹350',
    },
    {
      'title': 'Dune',
      'author': 'Frank Herbert',
      'cover': 'https://images-na.ssl-images-amazon.com/images/I/81ym3QUd3KL.jpg',
      'rating': '★ 4.8',
      'price': '₹499',
    },
  ];

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 240,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 240,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER & CAROUSEL NAVIGATION ARROWS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'You may also like',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D3B2E),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                InkWell(
                  onTap: _scrollLeft,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.chevron_left, size: 20, color: Color(0xFF2D3748)),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _scrollRight,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF2D3748)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // CAROUSEL OF RECOMMENDED BOOK CARDS
        SizedBox(
          height: 250,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _sampleRecommendations.length,
            itemBuilder: (context, idx) {
              final item = _sampleRecommendations[idx];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDF2F7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item['cover']!,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 140,
                          color: const Color(0xFFCBD5E0),
                          child: const Icon(Icons.book, color: Color(0xFF0D3B2E)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                    Text(
                      item['author']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF718096),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['rating']!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD69E2E),
                          ),
                        ),
                        Text(
                          item['price']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
