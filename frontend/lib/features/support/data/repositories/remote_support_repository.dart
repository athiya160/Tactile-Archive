import '../../../../core/network/api_client.dart';
import '../../domain/entities/faq.dart';
import '../../domain/repositories/support_repository.dart';
import 'mock_support_repository.dart';

class RemoteSupportRepository implements SupportRepository {
  final ApiClient apiClient;
  final MockSupportRepository _fallback = MockSupportRepository();

  RemoteSupportRepository(this.apiClient);

  @override
  Future<List<Faq>> getFaqs() async {
    try {
      final response = await apiClient.getJson('/support/faqs');
      if (response is List) {
        final faqs = response.map((item) {
          final data = item as Map<String, dynamic>;
          return Faq(
            question: data['question']?.toString() ?? '',
            answer: data['answer']?.toString() ?? '',
          );
        }).toList();
        if (faqs.isNotEmpty) {
          return faqs;
        }
      }
    } catch (_) {
      // Fallback gracefully to mock FAQs when offline
    }
    return _fallback.getFaqs();
  }

  @override
  Future<List<Faq>> searchFaqs(String query) async {
    try {
      final response = await apiClient.getJson(
        '/support/faqs/search',
        queryParameters: {'q': query},
      );
      if (response is List) {
        final faqs = response.map((item) {
          final data = item as Map<String, dynamic>;
          return Faq(
            question: data['question']?.toString() ?? '',
            answer: data['answer']?.toString() ?? '',
          );
        }).toList();
        if (faqs.isNotEmpty) {
          return faqs;
        }
      }
    } catch (_) {
      // Fallback gracefully to mock FAQs when offline
    }
    return _fallback.searchFaqs(query);
  }
}
