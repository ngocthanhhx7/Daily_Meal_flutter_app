import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_api.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/profile_screen.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PublicUser _user({bool following = false}) => PublicUser.fromJson({
  'id': 'user-1',
  'displayName': 'Bếp Nhà',
  'bio': 'Món ngon mỗi ngày',
  'counts': {'posts': 1, 'followers': 2, 'following': 3},
  'relationship': {'isFollowing': following},
});

class _Repository implements ProfileRepositoryContract {
  @override
  Future<ProfileBundle> loadProfile(
    String userId, {
    required bool includeSaved,
  }) async => ProfileBundle(
    user: _user(),
    posts: [
      FeedPost.fromJson({
        '_id': 'post-1',
        'author': {'id': 'user-1', 'displayName': 'Bếp Nhà'},
        'caption': 'Bữa sáng đủ chất',
        'visibility': 'public',
        'createdAt': '2026-07-11T08:00:00Z',
        'updatedAt': '2026-07-11T08:00:00Z',
      }),
    ],
    savedPosts: const [],
  );

  @override
  Future<List<PublicUser>> loadFollows(
    String userId, {
    required bool followers,
  }) async => [
    PublicUser.fromJson({'id': 'user-2', 'displayName': 'Bạn Bếp'}),
  ];

  @override
  Future<PublicUser> setFollowing(
    String userId, {
    required bool following,
  }) async => _user(following: following);

  @override
  Future<PublicUser> updateMe(Map<String, dynamic> changes) async =>
      PublicUser.fromJson({
        'id': 'user-1',
        'displayName': changes['displayName'],
        'bio': changes['bio'],
      });
}

void main() {
  testWidgets(
    'public profile renders content, follows user and opens followers',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = ProfileController(
        _Repository(),
        userId: 'user-1',
        isOwner: false,
      );
      addTearDown(controller.dispose);
      await controller.load();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(
              controller: controller,
              mediaResolver: MediaUrlResolver(
                Uri.parse('https://api.dailymeal.site'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bếp Nhà'), findsOneWidget);
      expect(find.text('Bữa sáng đủ chất'), findsOneWidget);
      await tester.tap(find.text('Theo dõi'));
      await tester.pumpAndSettle();
      expect(find.text('Đang theo dõi'), findsWidgets);

      await tester.tap(find.text('Người theo dõi'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn Bếp'), findsOneWidget);
    },
  );

  testWidgets(
    'owner edits display name and bio through production controller',
    (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = ProfileController(
        _Repository(),
        userId: 'user-1',
        isOwner: true,
      );
      addTearDown(controller.dispose);
      await controller.load();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(
              controller: controller,
              mediaResolver: MediaUrlResolver(
                Uri.parse('https://api.dailymeal.site'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa hồ sơ'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Tên hiển thị'),
        'Bếp Mới',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Giới thiệu'),
        'Món mới',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('Bếp Mới'), findsOneWidget);
      expect(find.text('Món mới'), findsOneWidget);
    },
  );
}
