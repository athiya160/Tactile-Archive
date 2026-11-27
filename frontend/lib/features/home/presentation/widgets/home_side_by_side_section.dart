import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/book.dart';

class HomeSideBySideSection extends StatelessWidget {
  final List<Book> featuredBooks;
  final Function(String) onCategorySelected;

  const HomeSideBySideSection({
    super.key,
    required this.featuredBooks,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDFBF7),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: BROWSE BY CATEGORY (50%)
                  Expanded(
                    flex: 5,
                    child: _buildCategoryColumn(context),
                  ),
                  const SizedBox(width: 40),
                  // RIGHT COLUMN: FEATURED BOOKS (50%)
                  Expanded(
                    flex: 6,
                    child: _buildFeaturedBooksColumn(context),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildCategoryColumn(context),
                const SizedBox(height: 48),
                _buildFeaturedBooksColumn(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryColumn(BuildContext context) {
    final categories = [
      {'name': 'Fiction', 'icon': FontAwesomeIcons.book, 'color': const Color(0xFFE8F5E9)},
      {'name': 'Non-Fiction', 'icon': FontAwesomeIcons.penNib, 'color': const Color(0xFFE0F2F1)},
      {'name': 'Academic', 'icon': FontAwesomeIcons.graduationCap, 'color': const Color(0xFFE8EAF6)},
      {'name': 'Children', 'icon': FontAwesomeIcons.childReaching, 'color': const Color(0xFFFCE4EC)},
      {'name': 'Comics', 'icon': FontAwesomeIcons.masksTheater, 'color': const Color(0xFFFFF3E0)},
      {'name': 'Magazines', 'icon': FontAwesomeIcons.newspaper, 'color': const Color(0xFFFFF8E1)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_outline, size: 18, color: Color(0xFF0D3B2E)),
                    const SizedBox(width: 8),
                    Text(
                      'Browse by Category',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore books by your favorite categories',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => context.go('/browse'),
              child: Row(
                children: [
                  Text(
                    'View all categories',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0D3B2E)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return InkWell(
              onTap: () => onCategorySelected(cat['name'] as String),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEDF2F7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cat['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        cat['icon'] as dynamic,
                        size: 16,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedBooksColumn(BuildContext context) {
    final sampleBooks = featuredBooks.isNotEmpty
        ? featuredBooks.take(5).toList()
        : [
            Book(
              id: '1',
              title: 'Atomic Habits',
              author: 'James Clear',
              coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg',
              price: 15.99,
              category: 'Self-Help',
              categories: const ['Self-Help'],
              listingType: ListingType.forSale,
              rating: 4.8,
              description: 'Tiny Changes, Remarkable Results.',
            ),
            Book(
              id: '2',
              title: 'The Alchemist',
              author: 'Paulo Coelho',
              coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/71aFt4+OTOL.jpg',
              price: 12.50,
              category: 'Fiction',
              categories: const ['Fiction'],
              listingType: ListingType.forSale,
              rating: 4.7,
              description: 'A fable about following your dream.',
            ),
            Book(
              id: '3',
              title: 'The Midnight Library',
              author: 'Matt Haig',
              coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81J6APjwHQL.jpg',
              price: 14.20,
              category: 'Fiction',
              categories: const ['Fiction'],
              listingType: ListingType.forSale,
              rating: 4.6,
              description: 'Between life and death there is a library.',
            ),
            Book(
              id: '4',
              title: 'Rich Dad Poor Dad',
              author: 'Robert T. Kiyosaki',
              coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81b-N2yL0DL.jpg',
              price: 11.99,
              category: 'Finance',
              categories: const ['Finance'],
              listingType: ListingType.forSale,
              rating: 4.7,
              description: 'What the rich teach their kids about money.',
            ),
            Book(
              id: '5',
              title: 'Thinking, Fast and Slow',
              author: 'Daniel Kahneman',
              coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/71f65fKq3RL.jpg',
              price: 16.50,
              category: 'Psychology',
              categories: const ['Psychology'],
              listingType: ListingType.forSale,
              rating: 4.5,
              description: 'The two systems that drive the way we think.',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_outline, size: 18, color: Color(0xFF0D3B2E)),
                    const SizedBox(width: 8),
                    Text(
                      'Featured Books',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Handpicked books from our community',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => context.go('/browse'),
              child: Row(
                children: [
                  Text(
                    'View all books',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0D3B2E)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sampleBooks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final book = sampleBooks[index];
              return InkWell(
                onTap: () => context.push('/book/${book.id}'),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 145,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          book.coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFF1E3A2B),
                            child: const Center(
                              child: Icon(Icons.book, color: Colors.white54, size: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
