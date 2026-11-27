import 'package:libri_flow/core/widgets/ivory_scaffold.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';


import '../bloc/feedback_bloc.dart';

import '../bloc/feedback_event.dart';

import '../bloc/feedback_state.dart';

import '../widgets/feedback_dropdown.dart';

import '../widgets/human_review_card.dart';

import '../widgets/star_rating_row.dart';

import 'package:libri_flow/core/design_system/design_system.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      title: 'Feedback',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: BlocConsumer<FeedbackBloc, FeedbackState>(
        listener: (context, state) {
          if (state.status == FeedbackStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you for your feedback!'),
                backgroundColor: DSColors.primary,
              ),
            );
            context.pop();
          } else if (state.status == FeedbackStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong'),
                backgroundColor: DSColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 100,
              left: DSSpacing.lg,
              right: DSSpacing.lg,
              bottom: DSSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your thoughts shape the future of our digital sanctuary. Share your experiences or report an issue with the curator.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DSColors.textLight,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                StarRatingRow(
                  rating: state.feedback.rating,
                  onRatingChanged: (rating) {
                    context.read<FeedbackBloc>().add(
                      FeedbackRatingChanged(rating),
                    );
                  },
                ),
                const SizedBox(height: DSSpacing.xl),
                FeedbackDropdown(
                  value: state.feedback.reason,
                  onChanged: (reason) {
                    if (reason != null) {
                      context.read<FeedbackBloc>().add(
                        FeedbackReasonChanged(reason),
                      );
                    }
                  },
                ),
                const SizedBox(height: DSSpacing.xl),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DETAILED THOUGHTS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: DSColors.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: DSColors.surface,
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          context.read<FeedbackBloc>().add(
                            FeedbackCommentsChanged(value),
                          );
                        },
                        maxLines: 6,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText:
                              'Describe your experience or the issue you encountered...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: DSColors.textLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                          contentPadding: const EdgeInsets.all(DSSpacing.md),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.xl),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DSColors.primary, DSColors.primaryHover],
                    ),
                    borderRadius: BorderRadius.circular(DSRadius.lg),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: state.status == FeedbackStatus.loading
                        ? null
                        : () => context.read<FeedbackBloc>().add(
                            FeedbackSubmitted(),
                          ),
                    icon: state.status == FeedbackStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                    label: Text(
                      state.status == FeedbackStatus.loading
                          ? 'SUBMITTING...'
                          : 'SUBMIT',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const HumanReviewCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}
