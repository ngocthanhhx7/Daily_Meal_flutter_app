import 'package:daily_meal_flutter_app/features/comments/data/comments_repository.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:flutter/foundation.dart';

enum CommentsStatus { idle, loading, ready, empty, failure }

class CommentsState {
  const CommentsState({
    required this.status,
    required this.comments,
    this.isSending = false,
    this.errorMessage,
  });

  const CommentsState.idle()
    : this(status: CommentsStatus.idle, comments: const []);

  final CommentsStatus status;
  final List<PostComment> comments;
  final bool isSending;
  final String? errorMessage;

  CommentsState copyWith({
    CommentsStatus? status,
    List<PostComment>? comments,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) => CommentsState(
    status: status ?? this.status,
    comments: comments ?? this.comments,
    isSending: isSending ?? this.isSending,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class CommentsController extends ChangeNotifier {
  CommentsController(this.postId, this._repository);

  final String postId;
  final CommentsRepositoryContract _repository;
  CommentsState _state = const CommentsState.idle();

  CommentsState get state => _state;

  Future<void> load() async {
    _setState(
      _state.copyWith(status: CommentsStatus.loading, clearError: true),
    );
    try {
      final comments = await _repository.load(postId);
      _setState(
        CommentsState(
          status: comments.isEmpty
              ? CommentsStatus.empty
              : CommentsStatus.ready,
          comments: comments,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          status: CommentsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> send(String body) async {
    if (_state.isSending) return;
    _setState(_state.copyWith(isSending: true, clearError: true));
    try {
      receive(await _repository.create(postId, body));
    } catch (error) {
      _setState(
        _state.copyWith(isSending: false, errorMessage: error.toString()),
      );
      rethrow;
    } finally {
      if (_state.isSending) _setState(_state.copyWith(isSending: false));
    }
  }

  void receive(PostComment comment) {
    if (_state.comments.any((item) => item.id == comment.id)) {
      if (_state.isSending) _setState(_state.copyWith(isSending: false));
      return;
    }
    final comments = [..._state.comments, comment]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _setState(CommentsState(status: CommentsStatus.ready, comments: comments));
  }

  void _setState(CommentsState next) {
    _state = next;
    notifyListeners();
  }
}
