import 'package:daily_meal_flutter_app/features/feed/presentation/post_media.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('video autoplay boundary requires at least 65 percent visibility', () {
    expect(shouldPlayVisibleVideo(.64), isFalse);
    expect(shouldPlayVisibleVideo(.65), isTrue);
    expect(shouldPlayVisibleVideo(1), isTrue);
  });
}
