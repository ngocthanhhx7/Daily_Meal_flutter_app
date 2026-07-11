import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_api.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter_test/flutter_test.dart';

PublicUser _user({bool following = false}) => PublicUser.fromJson({
  'id': 'user-1',
  'displayName': 'Bếp Nhà',
  'relationship': {'isFollowing': following, 'followsMe': true},
});

class _Repository implements ProfileRepositoryContract {
  bool failFollow = false;

  @override
  Future<ProfileBundle> loadProfile(
    String userId, {
    required bool includeSaved,
  }) async => ProfileBundle(
    user: _user(),
    posts: const <FeedPost>[],
    savedPosts: const <FeedPost>[],
  );

  @override
  Future<List<PublicUser>> loadFollows(
    String userId, {
    required bool followers,
  }) async => [_user()];

  @override
  Future<PublicUser> setFollowing(
    String userId, {
    required bool following,
  }) async {
    if (failFollow) throw StateError('network');
    return _user(following: following);
  }

  @override
  Future<PublicUser> updateMe(Map<String, dynamic> changes) async =>
      PublicUser.fromJson({
        'id': 'user-1',
        'displayName': changes['displayName'],
        'bio': changes['bio'],
      });
}

void main() {
  test('loads owner profile including saved posts', () async {
    final controller = ProfileController(
      _Repository(),
      userId: 'user-1',
      isOwner: true,
    );
    await controller.load();
    expect(controller.state.status, ProfileStatus.ready);
    expect(controller.state.user?.displayName, 'Bếp Nhà');
  });

  test('follow mutation rolls back on failure', () async {
    final repository = _Repository();
    final controller = ProfileController(
      repository,
      userId: 'user-1',
      isOwner: false,
    );
    await controller.load();
    repository.failFollow = true;
    final pending = controller.toggleFollow();
    expect(controller.state.user?.relationship.isFollowing, isTrue);
    await expectLater(pending, throwsStateError);
    expect(controller.state.user?.relationship.isFollowing, isFalse);
  });

  test('owner updates profile with the server response', () async {
    final controller = ProfileController(
      _Repository(),
      userId: 'user-1',
      isOwner: true,
    );
    await controller.load();
    await controller.updateProfile({
      'displayName': 'Bếp Mới',
      'bio': 'Món mới',
    });
    expect(controller.state.user?.displayName, 'Bếp Mới');
    expect(controller.state.user?.bio, 'Món mới');
  });
}
