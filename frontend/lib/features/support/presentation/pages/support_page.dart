import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/support_bloc.dart';
import '../bloc/support_event.dart';
import '../bloc/support_state.dart';
import '../widgets/support_search_bar.dart';
import '../widgets/faq_section.dart';
import '../widgets/contact_section.dart';
import '../widgets/report_issue_card.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/widgets/tactile_footer.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      title: 'Help & Support',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: BlocBuilder<SupportBloc, SupportState>(
        builder: (context, state) {
          if (state is SupportInitial) {
            context.read<SupportBloc>().add(SupportStarted());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SupportLoading) {
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
                  SizedBox(height: 64 + MediaQuery.of(context).padding.top),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.lg,
                      vertical: DSSpacing.lg,
                    ),
                    child: SupportSearchBar(
                      initialValue: state.query,
                      onChanged: (query) {
                        context.read<SupportBloc>().add(
                          SupportSearchQueryChanged(query),
                        );
                      },
                    ),
                  ),
                  FaqSection(faqs: state.faqs),
                  const ContactSection(),
                  ReportIssueCard(
                    onReportPressed: () {
                      context.push('/report-issue');
                    },
                  ),
                  const SizedBox(height: DSSpacing.xl),
                  const TactileFooter(),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
