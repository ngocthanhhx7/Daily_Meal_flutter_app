import 'dart:typed_data';

import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:daily_meal_flutter_app/features/post_editor/services/media_picker_service.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_api.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/profile_screen.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/saved_screen.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

PublicUser _user({bool following = false}) => PublicUser.fromJson({
  'id': 'user-1',
  'displayName': 'Bếp Nhà',
  'bio': 'Món ngon mỗi ngày',
  'birthday': {'day': 5, 'month': 5, 'visibility': 'dayMonth'},
  'counts': {'posts': 1, 'followers': 2, 'following': 3},
  'relationship': {'isFollowing': following},
});

class _Repository implements ProfileRepositoryContract {
  String? uploadedCategory;
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
    savedPosts: includeSaved
        ? [
            FeedPost.fromJson({
              '_id': 'saved-1',
              'author': {'id': 'user-2', 'displayName': 'Bếp Bạn'},
              'caption': 'Món đã lưu',
              'visibility': 'public',
              'createdAt': '2026-07-11T08:00:00Z',
              'updatedAt': '2026-07-11T08:00:00Z',
            }),
          ]
        : const [],
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
        'displayName': changes['displayName'] ?? 'Bếp Nhà',
        'bio': changes['bio'],
      });

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String category,
  }) async {
    uploadedCategory = category;
    return '/uploads/$category/$fileName';
  }

  @override
  Future<bool> setInteraction(
    String userId,
    String type, {
    required bool active,
    String? note,
  }) async => active;

  @override
  Future<List<PublicUser>> loadBlockedUsers() async => [_user()];
}

class _Picker implements MediaPickerService {
  @override
  Future<List<PickedMedia>> pickImages({required int limit}) async => [
    PickedMedia(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'avatar.jpg',
      mimeType: 'image/jpeg',
      mediaType: DraftMediaType.image,
    ),
  ];

  @override
  Future<PickedMedia?> captureImage() async => null;

  @override
  Future<PickedMedia?> pickVideo() async => null;
}

void main() {
  testWidgets('saved route renders its dedicated source composition', (
    tester,
  ) async {
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
          home: SavedScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Món đã lưu'), findsOneWidget);
  });

  testWidgets('owner post preview opens the edit-post route', (tester) async {
    final controller = ProfileController(
      _Repository(),
      userId: 'user-1',
      isOwner: true,
    );
    addTearDown(controller.dispose);
    await controller.load();
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, _) => ProfileScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
        GoRoute(
          path: '/posts/:id/edit',
          name: 'editPost',
          builder: (_, state) => Text('edit-${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-post-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('edit-post-1'), findsOneWidget);
  });

  testWidgets('owner exposes the source profile menu and shares profile', (
    tester,
  ) async {
    final controller = ProfileController(
      _Repository(),
      userId: 'user-1',
      isOwner: true,
    );
    addTearDown(controller.dispose);
    await controller.load();
    String? sharedUserId;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
            shareProfile: (user) async => sharedUserId = user.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-secondary-action')));
    await tester.pumpAndSettle();
    expect(sharedUserId, 'user-1');

    await tester.tap(find.byTooltip('Mở menu hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Tin nhắn'), findsWidgets);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

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

      expect(find.text('Bếp Nhà'), findsNWidgets(2));
      expect(find.text('Bữa sáng đủ chất'), findsOneWidget);
      expect(find.text('Sinh nhật 5/5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile-primary-action')));
      await tester.pumpAndSettle();
      expect(find.text('Đang theo dõi'), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Đã lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Món đã lưu'), findsOneWidget);

      await tester.tap(find.byTooltip('An toàn tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Sao chép tên để tìm kiếm'), findsOneWidget);
      await tester.tap(find.text('Chặn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('An toàn tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ chặn'), findsOneWidget);
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
      await tester.tap(find.text('Chỉnh sửa trang'));
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

      expect(find.text('Bếp Mới'), findsNWidgets(2));
      expect(find.textContaining('Món mới'), findsOneWidget);
    },
  );

  testWidgets('owner picks and uploads an avatar', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    final controller = ProfileController(
      repository,
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
            mediaPicker: _Picker(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-avatar-action')));
    await tester.pumpAndSettle();
    expect(repository.uploadedCategory, 'avatar');
  });
}
