import 'package:flutter/material.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';
import 'package:libri_flow/features/home/presentation/widgets/browse_book_card.dart';

class BrowseBookGrid extends StatelessWidget {
  final List<Book> books;
  final bool isLoadingMore;

  const BrowseBookGrid({
    super.key,
    required this.books,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth >= 1024) {
      crossAxisCount = 4; // 4 columns for Browse Books page design
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    final double spacing = 32.0; // 2rem
    final double paddingHorizontal = screenWidth > 768
        ? 64.0
        : 32.0; // 32.0 on each side for tablet/desktop
    final double availableWidth = screenWidth - paddingHorizontal;
    final double cardWidth =
        (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

    // Adjust aspect ratio to match BookCard better
    // BookCard has a fixed layout aspect ratio depending on width
    final double childAspectRatio =
        cardWidth / (cardWidth * 1.6); // approximately 1:1.6

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return BrowseBookCard(book: books[index]);
      },
    );
  }
}
