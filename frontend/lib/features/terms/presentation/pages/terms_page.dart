import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import '../bloc/terms_bloc.dart';
import '../bloc/terms_event.dart';
import '../bloc/terms_state.dart';
import '../../domain/entities/terms_section.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TermsBloc, TermsState>(
      listener: (context, state) {
        if (state is TermsAcknowledgeSuccess) {
          context.pop();
        }
      },
      builder: (context, state) {
        return IvoryScaffold(
          title: 'Terms & Conditions',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: DSColors.primary),
            onPressed: () => context.pop(),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TermsState state) {
    if (state is TermsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DSColors.primary),
      );
    }
    if (state is TermsError) {
      return Center(child: Text(state.message));
    }
    if (state is TermsLoaded) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 88 + DSSpacing.xxl,
          bottom: DSSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last updated: ${state.lastUpdated}'.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DSColors.textLight,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.md),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: DSColors.borderLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.xxl),
                  ...state.sections.map(
                    (section) => _TermsSectionWidget(section: section),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 64),
                    padding: const EdgeInsets.only(top: 40),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: DSColors.borderLight),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: DSButton(
                      text: 'Acknowledge & Return',
                      onPressed: () {
                        context.read<TermsBloc>().add(TermsAcknowledged());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _TermsSectionWidget extends StatelessWidget {
  final TermsSection section;
  const _TermsSectionWidget({required this.section});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DSSpacing.md),
          ...section.paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.md),
              child: Text(
                p,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
          ),
          if (section.bullets != null)
            ...section.bullets!.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 12.0,
                  left: DSSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•',
                      style: TextStyle(
                        color: DSColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: DSSpacing.md),
                    Expanded(
                      child: Text(
                        bullet,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: DSColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
