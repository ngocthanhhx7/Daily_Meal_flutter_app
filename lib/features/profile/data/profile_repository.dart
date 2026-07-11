import 'package:daily_meal_flutter_app/features/profile/data/profile_api.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_api.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';

abstract interface class ProfileRepositoryContract {
  Future<ProfileBundle> loadProfile(
    String userId, {
    required bool includeSaved,
  });
  Future<List<PublicUser>> loadFollows(
    String userId, {
    required bool followers,
  });
  Future<PublicUser> setFollowing(String userId, {required bool following});
  Future<PublicUser> updateMe(Map<String, dynamic> changes);
}

class ProfileRepository implements ProfileRepositoryContract {
  ProfileRepository(this._profileApi, this._searchApi);
  final ProfileApi _profileApi;
  final SearchApi _searchApi;

  @override
  Future<ProfileBundle> loadProfile(
    String userId, {
    required bool includeSaved,
  }) => _profileApi.loadProfile(userId, includeSaved: includeSaved);

  @override
  Future<List<PublicUser>> loadFollows(
    String userId, {
    required bool followers,
  }) => _profileApi.loadFollows(userId, followers: followers);

  @override
  Future<PublicUser> setFollowing(String userId, {required bool following}) =>
      _searchApi.setFollowing(userId, following: following);

  @override
  Future<PublicUser> updateMe(Map<String, dynamic> changes) =>
      _profileApi.updateMe(changes);
}
