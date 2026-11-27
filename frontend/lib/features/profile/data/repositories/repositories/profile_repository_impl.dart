import '../../../../../core/services/api_service.dart';

class ProfileRepositoryImpl {
  Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.getProfile();
  }
}
