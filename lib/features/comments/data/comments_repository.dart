import 'package:daily_meal_flutter_app/features/comments/data/comments_api.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';

abstract interface class CommentsRepositoryContract {
  Future<List<PostComment>> load(String postId);
  Future<PostComment> create(String postId, String body);
}

class CommentsRepository implements CommentsRepositoryContract {
  CommentsRepository(this._api);
  final CommentsApi _api;

  @override
  Future<List<PostComment>> load(String postId) => _api.load(postId);

  @override
  Future<PostComment> create(String postId, String body) async {
    final normalized = body.trim();
    if (normalized.isEmpty || normalized.length > 500) {
      throw ArgumentError.value(
        body,
        'body',
        'Comment must be 1-500 characters',
      );
    }
    return _api.create(postId, normalized);
  }
}
