import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/add_book_review_bloc.dart';
import '../bloc/add_book_review_event.dart';
import '../bloc/add_book_review_state.dart';
import '../widgets/archive_standards_section.dart';
import '../widgets/archival_summary_section.dart';
import '../widgets/book_preview_card.dart';
import '../widgets/physical_copies_list.dart';
import 'package:libri_flow/features/add_book/presentation/widgets/step_indicator.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class AddBookReviewPage extends StatelessWidget {
  const AddBookReviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddBookReviewBloc, AddBookReviewState>(
      listener: (context, state) {
        if (state is AddBookReviewSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DSColors.primary,
            ),
          );
          // Navigate to home after success
          context.go('/');
        } else if (state is AddBookReviewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DSColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return IvoryScaffold(
          title: "Review & Publish",
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AddBookReviewState state) {
    if (state is AddBookReviewInitial || state is AddBookReviewLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AddBookReviewLoaded ||
        state is AddBookReviewActionInProgress) {
      final review = (state is AddBookReviewLoaded)
          ? state.review
          : (state as AddBookReviewActionInProgress).review;
      final isActionInProgress = state is AddBookReviewActionInProgress;
      return SingleChildScrollView(
        padding: EdgeInsets.only(
          left: DSSpacing.lg,
          right: DSSpacing.lg,
          top: 100 + MediaQuery.of(context).padding.top,
          bottom: DSSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepIndicator(
              currentStep: 3,
              totalSteps: 3,
              title: "Almost there..",
              progressOverride: review.progressPercent / 100,
            ),
            const SizedBox(height: DSSpacing.xxl),
            BookPreviewCard(
              title: review.title,
              author: review.author,
              isbn13: review.isbn13,
              edition: review.editionLabel,
              coverUrl: review.coverUrl,
            ),
            const SizedBox(height: DSSpacing.xl),
            ArchivalSummarySection(summary: review.summaryText),
            const SizedBox(height: DSSpacing.xl),
            PhysicalCopiesList(copies: review.copies),
            const SizedBox(height: DSSpacing.xl),
            ArchiveStandardsSection(standards: review.standards),
            const SizedBox(height: DSSpacing.xxl),
            _buildBottomActions(context, isActionInProgress),
            const SizedBox(height: DSSpacing.lg),
            _buildDecorativePanel(context),
          ],
        ),
      );
    }
    return const Center(child: Text("Something went wrong"));
  }

  Widget _buildBottomActions(BuildContext context, bool isActionInProgress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: DSButton(
            text: isActionInProgress ? "Publishing..." : "Publish",
            onPressed: isActionInProgress
                ? null
                : () => context.read<AddBookReviewBloc>().add(
                    AddBookReviewPublishPressed(),
                  ),
          ),
        ),
        const SizedBox(height: DSSpacing.md),
        SizedBox(
          width: double.infinity,
          child: DSButton(
            variant: DSButtonVariant.secondary,
            text: "Save as Draft",
            onPressed: isActionInProgress
                ? null
                : () => context.read<AddBookReviewBloc>().add(
                    AddBookReviewSaveDraftPressed(),
                  ),
          ),
        ),
        const SizedBox(height: DSSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
          child: Text(
            "By publishing, your entry will be reviewed for archival consistency within 24 hours.",
            textAlign: TextAlign.center,
            style: IvoryTheme.smallCapsLabel.copyWith(
              fontSize: 9,
              color: DSColors.border,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativePanel(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DSRadius.lg),
        image: const DecorationImage(
          image: NetworkImage(
            "https://images.unsplash.com/photo-1516979187457-637abb4f9353?q=80&w=2070&auto=format&fit=crop",
          ),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_outlined,
          color: DSColors.primary.withValues(alpha: 0.2),
          size: 48,
        ),
      ),
    );
  }
}
