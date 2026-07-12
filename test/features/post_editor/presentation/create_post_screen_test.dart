import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_controller.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/create_post_screen.dart';
import 'package:daily_meal_flutter_app/features/post_editor/services/media_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PickedMedia pickedImage([String fileName = 'meal.jpg']) => PickedMedia(
  bytes: Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  ),
  fileName: fileName,
  mimeType: 'image/jpeg',
  mediaType: DraftMediaType.image,
);

PickedMedia pickedVideo() => PickedMedia(
  bytes: Uint8List.fromList([4, 5, 6]),
  fileName: 'meal.mp4',
  mimeType: 'video/mp4',
  mediaType: DraftMediaType.video,
  durationMs: 12000,
);

class _Picker implements MediaPickerService {
  _Picker({this.images, this.video});

  final List<PickedMedia>? images;
  final PickedMedia? video;

  @override
  Future<PickedMedia?> captureImage() async => pickedImage();
  @override
  Future<List<PickedMedia>> pickImages({required int limit}) async =>
      images ?? [pickedImage()];
  @override
  Future<PickedMedia?> pickVideo() async => video;
}

class _Repository implements PostEditorRepositoryContract {
  PostDraft? published;

  @override
  Future<UploadedMedia> upload(PickedMedia media) async => const UploadedMedia(
    id: 'upload-1',
    mediaType: DraftMediaType.image,
    url: '/uploads/meal.jpg',
    mime: 'image/jpeg',
    size: 3,
  );

  @override
  Future<MealAnalysis> analyze(UploadedMedia upload, {String? hints}) async =>
      MealAnalysis(
        id: 'meal-1',
        result: const MealAnalysisResult(
          items: [],
          total: NutritionSummary(
            calories: 250,
            protein: 10,
            carbs: 30,
            fat: 8,
          ),
          warnings: [],
        ),
        createdAt: DateTime.utc(2026, 7, 11),
      );

  @override
  Future<List<PostSticker>> stickers() async => const [
    PostSticker(
      id: 'sticker-1',
      key: 'fresh',
      name: 'Fresh',
      assetPath: '/stickers/fresh.svg',
      premiumOnly: false,
    ),
  ];

  @override
  Future<PostSticker> createSticker({
    required String name,
    required String key,
    required String assetPath,
  }) async => PostSticker(
    id: 'custom-1',
    key: key,
    name: name,
    assetPath: assetPath,
    premiumOnly: true,
  );

  @override
  Future<FeedPost> publish(PostDraft draft) async {
    published = draft;
    return FeedPost.fromJson({
      '_id': 'post-1',
      'author': {'id': 'user-1', 'displayName': 'Meal'},
      ...draft.toJson(),
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T08:00:00Z',
    });
  }
}

void main() {
  testWidgets('premium capture switches between three images and one video', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PostEditorController(_Repository(), isPremium: true);
    final picker = _Picker(
      images: [
        pickedImage('one.jpg'),
        pickedImage('two.jpg'),
        pickedImage('three.jpg'),
      ],
      video: pickedVideo(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CreatePostScreen(controller: controller, picker: picker),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Chọn ảnh'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selected-media-0')), findsOneWidget);
    expect(find.byKey(const Key('selected-media-1')), findsOneWidget);
    expect(find.byKey(const Key('selected-media-2')), findsOneWidget);
    expect(controller.state.media, hasLength(3));

    await tester.tap(find.byTooltip('Chọn video'));
    await tester.pumpAndSettle();
    expect(controller.state.media, hasLength(1));
    expect(controller.state.media.single.mediaType, DraftMediaType.video);
    expect(find.byKey(const Key('selected-media-0')), findsOneWidget);
    expect(find.byKey(const Key('selected-media-1')), findsNothing);
  });

  testWidgets('selects media, analyzes and publishes a post', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    final controller = PostEditorController(repository, isPremium: true);
    FeedPost? published;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CreatePostScreen(
            controller: controller,
            picker: _Picker(),
            onPublished: (post) => published = post,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final galleryButton = find.byTooltip('Chọn ảnh');
    await tester.scrollUntilVisible(
      galleryButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(galleryButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selected-media-0')), findsOneWidget);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh bài viết'), findsOneWidget);
    expect(find.text('Riêng tư'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(CreatePostScreen.captionKey),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(CreatePostScreen.captionKey), 'Bữa trưa');
    await tester.enterText(
      find.byKey(CreatePostScreen.tagsKey),
      '#healthy lunch',
    );
    final analyzeButton = find.byKey(CreatePostScreen.analyzeKey);
    await tester.scrollUntilVisible(
      analyzeButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(analyzeButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('250 kcal'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Thêm nhãn dán'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm nhãn dán'));
    await tester.pumpAndSettle();
    expect(find.text('Nhãn dán'), findsOneWidget);
    await tester.tap(find.text('Fresh'));
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();

    final publishButton = find.byKey(CreatePostScreen.publishKey);
    await tester.scrollUntilVisible(
      publishButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(publishButton);
    await tester.pumpAndSettle();
    expect(published?.id, 'post-1');
    expect(repository.published?.caption, 'Bữa trưa');
    expect(repository.published?.tags, ['healthy', 'lunch']);
    expect(repository.published?.stickerId, 'sticker-1');
  });
}
