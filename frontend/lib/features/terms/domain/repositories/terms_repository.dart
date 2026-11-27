import '../entities/terms_section.dart';

abstract class TermsRepository {
  Future<List<TermsSection>> getTerms();

  Future<void> acknowledgeTerms();
}
