import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/report_issue_bloc.dart';
import '../bloc/report_issue_event.dart';
import '../bloc/report_issue_state.dart';
import '../widgets/report_dropdown.dart';
import '../widgets/attachment_card.dart';
import '../../domain/entities/issue_category.dart';
import '../../domain/entities/issue_severity.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ReportIssuePage extends StatelessWidget {
  const ReportIssuePage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportIssueBloc, ReportIssueState>(
      listener: (context, state) {
        if (state.status == ReportIssueStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted successfully!')),
          );
          context.pop();
        } else if (state.status == ReportIssueStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: IvoryScaffold(
        title: 'Report an Issue',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 64 + MediaQuery.of(context).padding.top + DSSpacing.lg,
            left: DSSpacing.lg,
            right: DSSpacing.lg,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<ReportIssueBloc, ReportIssueState>(
                buildWhen: (p, c) => p.issue.category != c.issue.category,
                builder: (context, state) {
                  return ReportDropdown<IssueCategory>(
                    label: 'Category',
                    hint: 'Select an issue category',
                    value: state.issue.category,
                    items: IssueCategory.values
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.label)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<ReportIssueBloc>().add(
                          ReportIssueCategoryChanged(val),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: DSSpacing.lg),
              BlocBuilder<ReportIssueBloc, ReportIssueState>(
                buildWhen: (p, c) => p.issue.severity != c.issue.severity,
                builder: (context, state) {
                  return ReportDropdown<IssueSeverity>(
                    label: 'Severity',
                    hint: 'Select severity level',
                    value: state.issue.severity,
                    items: IssueSeverity.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<ReportIssueBloc>().add(
                          ReportIssueSeverityChanged(val),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: DSSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: DSSpacing.xs,
                      bottom: 6.0,
                    ),
                    child: Text(
                      'DESCRIPTION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: DSColors.textLight,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: DSColors.borderLight,
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                      border: Border.all(
                        color: DSColors.borderLight.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      maxLines: 5,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue in detail...',
                        hintStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: DSColors.textLight.withValues(alpha: 0.5),
                            ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(DSSpacing.md),
                      ),
                      onChanged: (val) {
                        context.read<ReportIssueBloc>().add(
                          ReportIssueDescriptionChanged(val),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.xl),
              BlocBuilder<ReportIssueBloc, ReportIssueState>(
                buildWhen: (p, c) => p.issue.attachments != c.issue.attachments,
                builder: (context, state) {
                  return AttachmentCard(
                    attachments: state.issue.attachments,
                    onAttachmentAdded: (path) {
                      context.read<ReportIssueBloc>().add(
                        ReportIssueAttachmentAdded(path),
                      );
                    },
                    onAttachmentRemoved: (path) {
                      context.read<ReportIssueBloc>().add(
                        ReportIssueAttachmentRemoved(path),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(DSSpacing.lg),
          child: BlocBuilder<ReportIssueBloc, ReportIssueState>(
            builder: (context, state) {
              return Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DSColors.primary, DSColors.primaryHover],
                  ),
                  borderRadius: BorderRadius.circular(DSRadius.lg),
                  boxShadow: DSShadows.md,
                ),
                child: ElevatedButton(
                  onPressed: state.status == ReportIssueStatus.loading
                      ? null
                      : () {
                          context.read<ReportIssueBloc>().add(
                            ReportIssueSubmitted(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                    ),
                  ),
                  child: state.status == ReportIssueStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SUBMIT REPORT',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                            const SizedBox(width: DSSpacing.sm),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
