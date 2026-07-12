import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_repository.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/foundation.dart';

enum FeedStatus { idle, loading, ready, empty, failure }

class FeedState {
  const FeedState({
    required this.status,
    required this.posts,
    required this.page,
    required this.hasMore,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const FeedState.idle()
    : this(status: FeedStatus.idle, posts: const [], page: 0, hasMore: true);

  final FeedStatus status;
  final List<FeedPost> posts;
  final int page;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;

  FeedState copyWith({
    FeedStatus? status,
    List<FeedPost>? posts,
    int? page,
    bool? hasMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => FeedState(
    status: status ?? this.status,
    posts: posts ?? this.posts,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class FeedController extends ChangeNotifier {
  FeedController(this._repository, {this.pageSize = 20});

  final FeedRepositoryContract _repository;
  final int pageSize;
  FeedState _state = const FeedState.idle();
  final Set<String> _busyInteractions = {};

  FeedState get state => _state;
  bool isInteractionBusy(String postId) => _busyInteractions.contains(postId);

  void applyPost(FeedPost post) {
    final index = _state.posts.indexWhere((item) => item.id == post.id);
    if (index >= 0) _replacePost(index, post);
  }

  void removePost(String postId) {
    final posts = _state.posts.where((post) => post.id != postId).toList();
    if (posts.length == _state.posts.length) return;
    _setState(
      _state.copyWith(
        posts: posts,
        status: posts.isEmpty ? FeedStatus.empty : FeedStatus.ready,
      ),
    );
  }

  Future<void> loadInitial() async {
    if (_state.status == FeedStatus.loading) return;
    _setState(_state.copyWith(status: FeedStatus.loading, clearError: true));
    try {
      final page = await _repository.loadPage(page: 1, limit: pageSize);
      _setPage(page, replace: true);
    } catch (error) {
      _setState(
        _state.copyWith(
          status: FeedStatus.failure,
          errorMessage: userErrorMessage(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    if (_state.isRefreshing) return;
    _setState(_state.copyWith(isRefreshing: true, clearError: true));
    try {
      _setPage(
        await _repository.loadPage(page: 1, limit: pageSize),
        replace: true,
        refreshing: false,
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          isRefreshing: false,
          errorMessage: userErrorMessage(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (!_state.hasMore || _state.isLoadingMore || _state.posts.isEmpty) return;
    _setState(_state.copyWith(isLoadingMore: true, clearError: true));
    try {
      _setPage(
        await _repository.loadPage(page: _state.page + 1, limit: pageSize),
        replace: false,
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          isLoadingMore: false,
          errorMessage: userErrorMessage(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> toggleLike(String postId) => _toggle(
    postId,
    isLike: true,
    request: () => _repository.toggleLike(postId),
  );

  Future<void> toggleSave(String postId) => _toggle(
    postId,
    isLike: false,
    request: () => _repository.toggleSave(postId),
  );

  Future<void> _toggle(
    String postId, {
    required bool isLike,
    required Future<FeedMutation> Function() request,
  }) async {
    if (!_busyInteractions.add(postId)) return;
    final index = _state.posts.indexWhere((post) => post.id == postId);
    if (index < 0) {
      _busyInteractions.remove(postId);
      return;
    }
    final original = _state.posts[index];
    final active = isLike
        ? !original.viewerState.liked
        : !original.viewerState.saved;
    final optimisticStats = PostStats(
      likes: isLike
          ? (original.stats.likes + (active ? 1 : -1)).clamp(0, 1 << 31)
          : original.stats.likes,
      comments: original.stats.comments,
      saves: !isLike
          ? (original.stats.saves + (active ? 1 : -1)).clamp(0, 1 << 31)
          : original.stats.saves,
    );
    _replacePost(
      index,
      original.withInteraction(
        nextStats: optimisticStats,
        liked: isLike ? active : null,
        saved: isLike ? null : active,
      ),
    );
    try {
      final result = await request();
      final currentIndex = _state.posts.indexWhere((post) => post.id == postId);
      if (currentIndex >= 0) {
        _replacePost(
          currentIndex,
          _state.posts[currentIndex].withInteraction(
            nextStats: result.stats,
            liked: isLike ? result.active : null,
            saved: isLike ? null : result.active,
          ),
        );
      }
    } catch (error) {
      final currentIndex = _state.posts.indexWhere((post) => post.id == postId);
      if (currentIndex >= 0) _replacePost(currentIndex, original);
      _setState(_state.copyWith(errorMessage: userErrorMessage(error)));
      rethrow;
    } finally {
      _busyInteractions.remove(postId);
      notifyListeners();
    }
  }

  void _setPage(
    FeedPage result, {
    required bool replace,
    bool refreshing = false,
  }) {
    final posts = replace
        ? result.posts
        : _deduplicate([..._state.posts, ...result.posts]);
    _setState(
      FeedState(
        status: posts.isEmpty ? FeedStatus.empty : FeedStatus.ready,
        posts: posts,
        page: result.page,
        hasMore: result.hasMore,
        isRefreshing: refreshing,
      ),
    );
  }

  List<FeedPost> _deduplicate(List<FeedPost> posts) {
    final seen = <String>{};
    return posts.where((post) => seen.add(post.id)).toList(growable: false);
  }

  void _replacePost(int index, FeedPost post) {
    final posts = [..._state.posts]..[index] = post;
    _setState(_state.copyWith(posts: posts));
  }

  void _setState(FeedState next) {
    _state = next;
    notifyListeners();
  }
}
