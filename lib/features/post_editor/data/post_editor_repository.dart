import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_api.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';

abstract interface class PostEditorRepositoryContract {
  Future<UploadedMedia> upload(PickedMedia media);
  Future<MealAnalysis> analyze(UploadedMedia upload, {String? hints});
  Future<List<PostSticker>> stickers();
  Future<PostSticker> createSticker({
    required String name,
    required String key,
    required String assetPath,
  });
  Future<FeedPost> publish(PostDraft draft);
}

class PostEditorRepository implements PostEditorRepositoryContract {
  PostEditorRepository(this._api);
  final PostEditorApi _api;

  @override
  Future<UploadedMedia> upload(PickedMedia media) => _api.upload(
    bytes: media.bytes,
    fileName: media.fileName,
    mimeType: media.mimeType,
    mediaType: media.mediaType,
  );

  @override
  Future<MealAnalysis> analyze(UploadedMedia upload, {String? hints}) =>
      _api.analyze(upload.id, hints: hints);

  @override
  Future<List<PostSticker>> stickers() => _api.stickers();

  @override
  Future<PostSticker> createSticker({
    required String name,
    required String key,
    required String assetPath,
  }) => _api.createSticker(name: name, key: key, assetPath: assetPath);

  @override
  Future<FeedPost> publish(PostDraft draft) => _api.createPost(draft);
}

abstract interface class PostManagementRepositoryContract {
  Future<FeedPost> update(
    String postId, {
    required String caption,
    required List<String> tags,
  });
  Future<void> delete(String postId);
}

class PostManagementRepository implements PostManagementRepositoryContract {
  PostManagementRepository(this._api);
  final PostEditorApi _api;

  @override
  Future<FeedPost> update(
    String postId, {
    required String caption,
    required List<String> tags,
  }) => _api.updatePost(postId, caption: caption, tags: tags);

  @override
  Future<void> delete(String postId) => _api.deletePost(postId);
}
