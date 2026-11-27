import '../../../../core/network/api_client.dart';
import '../../domain/entities/terms_section.dart';
import '../../domain/repositories/terms_repository.dart';

class RemoteTermsRepository implements TermsRepository {
  final ApiClient apiClient;

  RemoteTermsRepository(this.apiClient);

  @override
  Future<List<TermsSection>> getTerms() async {
    final response = await apiClient.getJson('/terms');
    if (response is List) {
      return response.map((item) {
        final data = item as Map<String, dynamic>;
        return TermsSection(
          title: data['title']?.toString() ?? '',
          paragraphs: List<String>.from(data['paragraphs'] ?? []),
          bullets: data['bullets'] != null
              ? List<String>.from(data['bullets'])
              : null,
        );
      }).toList();
    }
    throw Exception('Invalid terms response');
  }

  @override
  Future<void> acknowledgeTerms() async {
    await apiClient.postJson('/terms/acknowledge');
  }
}
