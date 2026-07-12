import 'package:daily_meal_flutter_app/features/feed/presentation/post_media.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('video autoplay boundary requires at least 65 percent visibility', () {
    expect(shouldPlayVisibleVideo(.64), isFalse);
    expect(shouldPlayVisibleVideo(.65), isTrue);
    expect(shouldPlayVisibleVideo(1), isTrue);
  });

  test('sizes feed image cache near its rendered physical width', () {
    expect(feedImageCacheWidth(276, 2.5), 690);
    expect(feedImageCacheWidth(100, 1), 320);
    expect(feedImageCacheWidth(1200, 3), 2048);
  });

  test('matches source collapsed frames for two-image grid', () {
    final frames = collapsedFeedImageFrames(PostLayout.grid, 2, 380, 500);
    expect(frames, hasLength(2));
    expect(frames.first.left, closeTo(7.6, .01));
    expect(frames.first.width, closeTo(209, .01));
    expect(frames.first.height, closeTo(360, .01));
    expect(frames.last.rotation, 2);
  });

  test('matches source spread composition for three images', () {
    final frames = spreadFeedImageFrames(3, 380, 500);
    expect(frames, hasLength(3));
    expect(frames.first.width, closeTo(212.8, .01));
    expect(frames.first.top, 75);
    expect(frames[1].left, greaterThan(frames.first.left));
    expect(frames[2].top, greaterThan(frames.first.top));
  });
}
