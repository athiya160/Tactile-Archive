import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/support_bloc.dart';
import '../bloc/support_state.dart';
import '../widgets/faq_item.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/widgets/tactile_footer.dart';

class FaqsPage extends StatelessWidget {
  const FaqsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      body: SafeArea(
        child: BlocBuilder<SupportBloc, SupportState>(
          builder: (context, state) {
            if (state is SupportInitial || state is SupportLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SupportError) {
              return Center(child: Text(state.message));
            }

            if (state is SupportLoaded) {
              return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: DSSpacing.lg,
                    right: DSSpacing.lg,
                    bottom: DSSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: DSColors.textDark,
                                ),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: DSSpacing.sm),
                              Text(
                                'Frequently Asked Questions',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: DSSpacing.xl),
                          ...state.faqs.map((faq) => FaqItem(faq: faq)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const TactileFooter(),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
