import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:daily_meal_flutter_app/features/post_editor/services/media_duration_probe.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

abstract interface class MediaPickerService {
  Future<List<PickedMedia>> pickImages({required int limit});
  Future<PickedMedia?> captureImage();
  Future<PickedMedia?> pickVideo();
}

class PluginMediaPickerService implements MediaPickerService {
  PluginMediaPickerService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedMedia>> pickImages({required int limit}) async {
    final files = await _picker.pickMultiImage(limit: limit, imageQuality: 92);
    final result = <PickedMedia>[];
    for (final file in files.take(limit)) {
      result.add(await _fromFile(file, DraftMediaType.image));
    }
    return result;
  }

  @override
  Future<PickedMedia?> captureImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    return file == null ? null : _fromFile(file, DraftMediaType.image);
  }

  @override
  Future<PickedMedia?> pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (file == null) return null;
    final durationMs = await probeVideoDurationMs(file.path);
    return _fromFile(file, DraftMediaType.video, durationMs: durationMs);
  }

  Future<PickedMedia> _fromFile(
    XFile file,
    DraftMediaType type, {
    int? durationMs,
  }) async {
    final bytes = await file.readAsBytes();
    final mimeType =
        file.mimeType ??
        lookupMimeType(file.name, headerBytes: bytes.take(16).toList()) ??
        (type == DraftMediaType.video ? 'video/mp4' : 'image/jpeg');
    return PickedMedia(
      bytes: bytes,
      fileName: file.name,
      mimeType: mimeType,
      mediaType: type,
      durationMs: durationMs,
    );
  }
}
