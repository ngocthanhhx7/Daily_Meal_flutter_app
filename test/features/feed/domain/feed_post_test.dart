import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes the complete production post payload', () {
    final post = FeedPost.fromJson({
      '_id': 'post-1',
      'author': {
        'id': 'user-1',
        'displayName': 'Bếp Nhà',
        'avatarUrl': '/uploads/avatar.jpg',
        'isPremium': true,
        'streakDays': 4,
      },
      'mediaType': 'video',
      'images': [
        {'url': '/uploads/cover.jpg', 'uploadId': 'upload-1'},
      ],
      'video': {
        'url': '/uploads/meal.mp4',
        'mime': 'video/mp4',
        'size': 1200,
        'durationMs': 3000,
      },
      'layout': 'cascade',
      'imageTransforms': [
        {'scale': 1.2, 'rotation': 5, 'offsetX': 2, 'offsetY': -3},
      ],
      'caption': 'Bữa tối',
      'tags': ['healthy'],
      'recipe': {
        'title': 'Salad',
        'ingredients': ['rau'],
        'steps': ['trộn'],
      },
      'nutritionSummary': {
        'calories': 320,
        'protein': 20,
        'carbs': 30,
        'fat': 10,
        'confidence': 0.9,
      },
      'stickerId': {
        '_id': 'sticker-1',
        'key': 'fresh',
        'name': 'Fresh',
        'assetPath': '/stickers/fresh.svg',
        'premiumOnly': false,
      },
      'visibility': 'friends',
      'stats': {'likes': 7, 'comments': 2, 'saves': 3},
      'viewerState': {'liked': true, 'saved': false},
      'createdAt': '2026-07-11T08:00:00.000Z',
      'updatedAt': '2026-07-11T09:00:00.000Z',
    });

    expect(post.id, 'post-1');
    expect(post.author.displayName, 'Bếp Nhà');
    expect(post.mediaType, PostMediaType.video);
    expect(post.video?.durationMs, 3000);
    expect(post.layout, PostLayout.cascade);
    expect(post.imageTransforms.single.offsetY, -3);
    expect(post.recipe?.ingredients, ['rau']);
    expect(post.nutritionSummary?.calories, 320);
    expect(post.sticker?.key, 'fresh');
    expect(post.visibility, PostVisibility.friends);
    expect(post.viewerState.liked, isTrue);
    expect(post.createdAt.toUtc().year, 2026);
  });

  test('uses server-compatible defaults for optional post fields', () {
    final post = FeedPost.fromJson({
      '_id': 'post-2',
      'author': {'id': 'user-2', 'displayName': 'Meal'},
      'caption': '',
      'visibility': 'public',
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T08:00:00Z',
    });

    expect(post.mediaType, PostMediaType.image);
    expect(post.images, isEmpty);
    expect(post.tags, isEmpty);
    expect(post.stats.likes, 0);
    expect(post.viewerState.saved, isFalse);
  });

  test('rejects missing post id and unknown enum values', () {
    expect(
      () => FeedPost.fromJson({
        'author': {'id': 'user', 'displayName': 'Meal'},
        'visibility': 'public',
        'createdAt': '2026-07-11T08:00:00Z',
        'updatedAt': '2026-07-11T08:00:00Z',
      }),
      throwsFormatException,
    );
    expect(
      () => FeedPost.fromJson({
        '_id': 'post',
        'author': {'id': 'user', 'displayName': 'Meal'},
        'mediaType': 'audio',
        'visibility': 'public',
        'createdAt': '2026-07-11T08:00:00Z',
        'updatedAt': '2026-07-11T08:00:00Z',
      }),
      throwsFormatException,
    );
  });
}
