import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/submit_report.dart';
import 'report_issue_event.dart';
import 'report_issue_state.dart';

class ReportIssueBloc extends Bloc<ReportIssueEvent, ReportIssueState> {
  final SubmitReport submitReport;

  ReportIssueBloc({required this.submitReport})
    : super(const ReportIssueState()) {
    on<ReportIssueStarted>(_onStarted);
    on<ReportIssueCategoryChanged>(_onCategoryChanged);
    on<ReportIssueSeverityChanged>(_onSeverityChanged);
    on<ReportIssueDescriptionChanged>(_onDescriptionChanged);
    on<ReportIssueAttachmentAdded>(_onAttachmentAdded);
    on<ReportIssueAttachmentRemoved>(_onAttachmentRemoved);
    on<ReportIssueSubmitted>(_onSubmitted);
  }

  void _onStarted(ReportIssueStarted event, Emitter<ReportIssueState> emit) {
    // Form initialized with default state; no async work needed
    emit(state); // Ensures state is emitted
  }

  void _onCategoryChanged(
    ReportIssueCategoryChanged event,
    Emitter<ReportIssueState> emit,
  ) {
    emit(state.copyWith(issue: state.issue.copyWith(category: event.category)));
  }

  void _onSeverityChanged(
    ReportIssueSeverityChanged event,
    Emitter<ReportIssueState> emit,
  ) {
    emit(state.copyWith(issue: state.issue.copyWith(severity: event.severity)));
  }

  void _onDescriptionChanged(
    ReportIssueDescriptionChanged event,
    Emitter<ReportIssueState> emit,
  ) {
    emit(
      state.copyWith(
        issue: state.issue.copyWith(description: event.description),
      ),
    );
  }

  void _onAttachmentAdded(
    ReportIssueAttachmentAdded event,
    Emitter<ReportIssueState> emit,
  ) {
    final newAttachments = List<String>.from(state.issue.attachments)
      ..add(event.path);
    emit(
      state.copyWith(issue: state.issue.copyWith(attachments: newAttachments)),
    );
  }

  void _onAttachmentRemoved(
    ReportIssueAttachmentRemoved event,
    Emitter<ReportIssueState> emit,
  ) {
    final newAttachments = List<String>.from(state.issue.attachments)
      ..remove(event.path);
    emit(
      state.copyWith(issue: state.issue.copyWith(attachments: newAttachments)),
    );
  }

  Future<void> _onSubmitted(
    ReportIssueSubmitted event,
    Emitter<ReportIssueState> emit,
  ) async {
    if (state.issue.category == null ||
        state.issue.severity == null ||
        state.issue.description.isEmpty) {
      emit(
        state.copyWith(
          status: ReportIssueStatus.failure,
          errorMessage: 'Please fill in all required fields.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ReportIssueStatus.loading));

    final result = await submitReport(state.issue);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ReportIssueStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: ReportIssueStatus.success)),
    );
  }
}
