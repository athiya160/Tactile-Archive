import '../../domain/entities/draft_listing_review.dart';
import '../../domain/entities/physical_copy_review.dart';
import '../../domain/entities/standard_check_item.dart';
import '../../domain/repositories/draft_listing_repository.dart';

class MockDraftListingRepository implements DraftListingRepository {
  @override
  Future<DraftListingReview> getDraftReview(String draftId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const DraftListingReview(
      id: "draft-123",
      title: "The Architecture of Silence",
      author: "Julian V. Thorne",
      isbn13: "978-3-16-148410-0",
      editionLabel: "First Edition (1994)",
      summaryText:
          "A foundational exploration of minimal space and resonant acoustics in pre-war European structures. This copy has been maintained in a climate-controlled environment since 2008.",
      progressPercent: 99,
      copies: [
        PhysicalCopyReview(
          id: "copy-1",
          title: "Reference Copy",
          subtext: "Archival Box #442",
          chips: ["MINT", "CONDITION", "Not For Sale"],
          icon: "archive",
        ),
        PhysicalCopyReview(
          id: "copy-2",
          title: "Alpha",
          subtext: "Shelf B-12",
          chips: ["GOOD", "CONDITION"],
          price: "\$45.00",
          icon: "book",
        ),
      ],
      standards: [
        StandardCheckItem(
          id: "s1",
          text: "High-resolution cover scan attached",
        ),
        StandardCheckItem(
          id: "s2",
          text: "Physical condition verified by owner",
        ),
        StandardCheckItem(
          id: "s3",
          text: "ISBN metadata consistency check passed",
        ),
      ],
    );
  }

  @override
  Future<void> publish(String draftId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> saveDraft(String draftId) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
