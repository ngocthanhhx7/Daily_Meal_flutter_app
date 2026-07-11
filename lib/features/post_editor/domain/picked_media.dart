import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';

class PickedMedia {
  PickedMedia({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.mediaType,
    this.durationMs,
  }) {
    if (bytes.isEmpty) throw ArgumentError('Media file is empty');
    if (mediaType == DraftMediaType.image && bytes.length > maxImageBytes) {
      throw ArgumentError('Image must be 8 MB or smaller');
    }
    if (mediaType == DraftMediaType.video && bytes.length > maxVideoBytes) {
      throw ArgumentError('Video must be 50 MB or smaller');
    }
    if (durationMs != null && durationMs! > maxVideoDurationMs) {
      throw ArgumentError('Video must be 30 seconds or shorter');
    }
    if (!_supportedMimeTypes.contains(mimeType.toLowerCase())) {
      throw ArgumentError('Unsupported media MIME type: $mimeType');
    }
  }

  static const maxImageBytes = 8 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;
  static const maxVideoDurationMs = 30000;
  static const _supportedMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/quicktime',
    'video/x-m4v',
  };

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final DraftMediaType mediaType;
  final int? durationMs;
}
