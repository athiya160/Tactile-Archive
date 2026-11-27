import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';
import 'package:libri_flow/features/home/presentation/widgets/book_card.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;
  final bool isLoadingMore;

  const BookGrid({super.key, required this.books, this.isLoadingMore = false});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth >= 1024) {
      crossAxisCount = 5;
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    final double spacing = DSSpacing.md;
    // 24px left and right padding inside HomePage container (total 48)
    final double paddingHorizontal = 48.0;
    final double availableWidth = screenWidth - paddingHorizontal;
    final double cardWidth =
        (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

    final double imageAspectRatio = 3 / 4;
    final double imageHeight = cardWidth / imageAspectRatio;
    // 178px represents the sum of title (36), author (16), rating (16), price (20), button (36) plus margins/paddings
    final double cardHeight = imageHeight + 178;
    final double childAspectRatio = cardWidth / cardHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: DSSpacing.xl,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return BookCard(book: books[index]);
      },
    );
  }
}
