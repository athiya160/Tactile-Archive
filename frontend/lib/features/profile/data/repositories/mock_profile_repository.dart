import '../../../../core/utils/result.dart';
import '../../domain/entities/profile_summary.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/services/api_service.dart';

class MockProfileRepository implements ProfileRepository {
  @override
  Future<Result<ProfileSummary>> getProfileSummary() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return Result.success(
      ProfileSummary(
        name: ApiService.userName ?? 'Julian Thorne',
        level: 'Curator Level Reader',
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuApGcaPh2fmSsLKG905vrDuDzJaCH5-I2DqiwfHO1dq3nuGi4gxX18UvztP-yKTMgJTQqWpebVCIzkn1G1MhHfT4IYKGAiP4_EM8951blzQji_9pGojPZD1OSMN3AEQ4hS-pkZ1tDn1R_qSCcOvtBUgwqbhKfH2NlJca49VS_DAQmH17HNdaK4zLyebo-9h4kfIfwZ4fN_P4u9X0cN9Awpqz0fdzR05hoybXfilgK6779TNVRPkyIetPsSxCJiMgFPbqVjZ4wp6hoK0',
        booksBorrowedCount: 42,
        booksSharedCount: 12,
        isAdmin: true,
      ),
    );
  }
}
