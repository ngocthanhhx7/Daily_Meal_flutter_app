import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes the exact post stats socket payload', () {
    final update = PostStatsUpdate.fromJson({
      'postId': 'post-1',
      'stats': {'likes': 7, 'comments': 5, 'saves': 3},
    });

    expect(update.postId, 'post-1');
    expect(update.stats.likes, 7);
    expect(update.stats.comments, 5);
    expect(update.stats.saves, 3);
  });

  test('rejects incomplete post stats socket payloads', () {
    expect(
      () => PostStatsUpdate.fromJson({
        'postId': 'post-1',
        'stats': {'likes': 1},
      }),
      throwsFormatException,
    );
  });
}
