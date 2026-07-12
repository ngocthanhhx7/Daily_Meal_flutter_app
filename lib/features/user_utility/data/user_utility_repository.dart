import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_api.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';

abstract interface class UserUtilityRepositoryContract {
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<PostSummaryPage> postSummary(PostSummaryFilter filter, {int page = 1});
  Future<List<SummaryPost>> userPosts(String userId);
  Future<AppUser> linkGoogle(String idToken);
}

class UserUtilityRepository implements UserUtilityRepositoryContract {
  UserUtilityRepository(this._api);
  final UserUtilityApi _api;
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _api.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
  @override
  Future<PostSummaryPage> postSummary(
    PostSummaryFilter filter, {
    int page = 1,
  }) => _api.postSummary(filter, page: page);
  @override
  Future<List<SummaryPost>> userPosts(String userId) => _api.userPosts(userId);
  @override
  Future<AppUser> linkGoogle(String idToken) => _api.linkGoogle(idToken);
}
