import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_controller.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:flutter_test/flutter_test.dart';

PickedMedia image(String name) => PickedMedia(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: name,
  mimeType: 'image/jpeg',
  mediaType: DraftMediaType.image,
);

class _Repository implements PostEditorRepositoryContract {
  bool failPublish = false;
  PostDraft? publishedDraft;

  @override
  Future<UploadedMedia> upload(PickedMedia media) async => UploadedMedia(
    id: 'upload-${media.fileName}',
    mediaType: media.mediaType,
    url: '/uploads/${media.fileName}',
    mime: media.mimeType,
    size: media.bytes.length,
  );

  @override
  Future<MealAnalysis> analyze(UploadedMedia upload, {String? hints}) async =>
      MealAnalysis(
        id: 'meal-1',
        result: const MealAnalysisResult(
          items: [],
          total: NutritionSummary(calories: 100, protein: 5, carbs: 10, fat: 2),
          warnings: [],
        ),
        createdAt: DateTime.utc(2026, 7, 11),
      );

  @override
  Future<List<PostSticker>> stickers() async => const [];

  @override
  Future<FeedPost> publish(PostDraft draft) async {
    publishedDraft = draft;
    if (failPublish) throw StateError('network');
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
  test('enforces free and premium media limits', () {
    final free = PostEditorController(_Repository(), isPremium: false);
    expect(
      () => free.selectImages([image('1.jpg'), image('2.jpg')]),
      throwsStateError,
    );
    expect(free.state.media, isEmpty);

    free.selectImages([image('1.jpg')]);
    expect(free.state.media.length, 1);

    final premium = PostEditorController(_Repository(), isPremium: true);
    premium.selectImages([image('1.jpg'), image('2.jpg'), image('3.jpg')]);
    expect(premium.state.media.length, 3);
    expect(() => premium.selectImages([image('4.jpg')]), throwsStateError);
  });

  test('analyzes each image and publishes the complete draft', () async {
    final repository = _Repository();
    final controller = PostEditorController(repository, isPremium: true);
    controller.selectImages([image('1.jpg'), image('2.jpg')]);
    controller.updateCaption('Bữa tối');
    controller.updateTags('Healthy, dinner #home');
    controller.updateVisibility(PostVisibility.friends);
    controller.updateRecipe(
      0,
      title: 'Cơm nhà',
      ingredients: 'gạo\nrau',
      steps: 'nấu cơm\nxào rau',
    );

    await controller.analyzeAll(hintsByImage: {0: 'ít dầu'});
    expect(controller.state.nutritionDetails.length, 2);

    final created = await controller.publish();
    expect(created.id, 'post-1');
    expect(repository.publishedDraft?.images.length, 2);
    expect(repository.publishedDraft?.tags, ['healthy', 'dinner', 'home']);
    expect(repository.publishedDraft?.recipes.single.ingredients, [
      'gạo',
      'rau',
    ]);
    expect(repository.publishedDraft?.nutritionDetails.length, 2);
  });

  test('preserves draft and exposes retry error on publish failure', () async {
    final repository = _Repository()..failPublish = true;
    final controller = PostEditorController(repository, isPremium: false);
    controller.selectImages([image('meal.jpg')]);
    controller.updateCaption('Retry');

    await expectLater(controller.publish(), throwsStateError);
    expect(controller.state.media.single.fileName, 'meal.jpg');
    expect(controller.state.caption, 'Retry');
    expect(controller.state.errorMessage, isNotNull);
    expect(controller.state.isBusy, isFalse);
  });
}
