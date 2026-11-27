import '../entities/faq.dart';

abstract class SupportRepository {
  Future<List<Faq>> getFaqs();

  Future<List<Faq>> searchFaqs(String query);
}
