import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/profile/application/blocked_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_api.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements ProfileRepositoryContract {
  bool fail = false;
  final blocked = PublicUser.fromJson({
    'id': 'blocked-1',
    'displayName': 'Đã chặn',
  });
  @override
  Future<List<PublicUser>> loadBlockedUsers() async => [blocked];
  @override
  Future<bool> setInteraction(
    String userId,
    String type, {
    required bool active,
    String? note,
  }) async {
    if (fail) throw StateError('network');
    return active;
  }

  @override
  Future<ProfileBundle> loadProfile(
    String userId, {
    required bool includeSaved,
  }) => throw UnimplementedError();
  @override
  Future<List<PublicUser>> loadFollows(
    String userId, {
    required bool followers,
  }) => throw UnimplementedError();
  @override
  Future<PublicUser> setFollowing(String userId, {required bool following}) =>
      throw UnimplementedError();
  @override
  Future<PublicUser> updateMe(Map<String, dynamic> changes) =>
      throw UnimplementedError();
  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String category,
  }) => throw UnimplementedError();
}

void main() {
  test('optimistically unblocks and rolls back on failure', () async {
    final repository = _Repository();
    final controller = BlockedController(repository);
    await controller.load();
    repository.fail = true;
    final pending = controller.unblock('blocked-1');
    expect(controller.users, isEmpty);
    await expectLater(pending, throwsStateError);
    expect(controller.users.single.id, 'blocked-1');
  });
}
