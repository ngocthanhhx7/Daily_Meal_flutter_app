import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts server-supported image and video MIME types', () {
    expect(
      PickedMedia(
        bytes: Uint8List.fromList([1]),
        fileName: 'meal.webp',
        mimeType: 'image/webp',
        mediaType: DraftMediaType.image,
      ).mimeType,
      'image/webp',
    );
    expect(
      PickedMedia(
        bytes: Uint8List.fromList([1]),
        fileName: 'meal.mov',
        mimeType: 'video/quicktime',
        mediaType: DraftMediaType.video,
        durationMs: 30000,
      ).durationMs,
      30000,
    );
  });

  test('rejects unsupported MIME and overlong videos', () {
    expect(
      () => PickedMedia(
        bytes: Uint8List.fromList([1]),
        fileName: 'bad.bmp',
        mimeType: 'image/bmp',
        mediaType: DraftMediaType.image,
      ),
      throwsArgumentError,
    );
    expect(
      () => PickedMedia(
        bytes: Uint8List.fromList([1]),
        fileName: 'long.mp4',
        mimeType: 'video/mp4',
        mediaType: DraftMediaType.video,
        durationMs: 30001,
      ),
      throwsArgumentError,
    );
  });
}
