import 'dart:async';

import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:daily_meal_flutter_app/features/search/domain/search_filters.dart';
import 'package:flutter/foundation.dart';

enum SearchMode { posts, people }

enum SearchStatus { idle, loading, ready, failure }

class SearchState {
  const SearchState({
    required this.status,
    required this.query,
    required this.mode,
    required this.filters,
    required this.posts,
    required this.users,
    this.errorMessage,
  });

  const SearchState.initial()
    : this(
        status: SearchStatus.idle,
        query: '',
        mode: SearchMode.posts,
        filters: const SearchFilters(),
        posts: const [],
        users: const [],
      );

  final SearchStatus status;
  final String query;
  final SearchMode mode;
  final SearchFilters filters;
  final List<FeedPost> posts;
  final List<PublicUser> users;
  final String? errorMessage;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    SearchMode? mode,
    SearchFilters? filters,
    List<FeedPost>? posts,
    List<PublicUser>? users,
    String? errorMessage,
    bool clearError = false,
  }) => SearchState(
    status: status ?? this.status,
    query: query ?? this.query,
    mode: mode ?? this.mode,
    filters: filters ?? this.filters,
    posts: posts ?? this.posts,
    users: users ?? this.users,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class SearchController extends ChangeNotifier {
  SearchController(
    this._repository, {
    this.debounceDuration = const Duration(milliseconds: 350),
  });

  final SearchRepositoryContract _repository;
  final Duration debounceDuration;
  SearchState _state = const SearchState.initial();
  Timer? _debounce;
  int _requestId = 0;
  final Set<String> _followingBusy = {};
  final Set<String> _postBusy = {};

  SearchState get state => _state;
  bool isFollowBusy(String userId) => _followingBusy.contains(userId);
  bool isPostBusy(String postId) => _postBusy.contains(postId);

  void updateQuery(String query) {
    _setState(_state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, searchNow);
  }

  void updateMode(SearchMode mode) => _setState(_state.copyWith(mode: mode));

  void updateFilters(SearchFilters filters) {
    _setState(_state.copyWith(filters: filters));
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, searchNow);
  }

  Future<void> searchNow() async {
    final requestId = ++_requestId;
    _setState(_state.copyWith(status: SearchStatus.loading, clearError: true));
    try {
      final result = await _repository.search(_state.query, _state.filters);
      if (requestId != _requestId) return;
      final mode =
          _state.mode == SearchMode.posts &&
              result.posts.isEmpty &&
              result.users.isNotEmpty
          ? SearchMode.people
          : _state.mode == SearchMode.people &&
                result.users.isEmpty &&
                result.posts.isNotEmpty
          ? SearchMode.posts
          : _state.mode;
      _setState(
        _state.copyWith(
          status: SearchStatus.ready,
          mode: mode,
          posts: result.posts,
          users: result.users,
        ),
      );
    } catch (error) {
      if (requestId != _requestId) return;
      _setState(
        _state.copyWith(
          status: SearchStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> toggleFollow(String userId) async {
    if (!_followingBusy.add(userId)) return;
    final index = _state.users.indexWhere((user) => user.id == userId);
    if (index < 0) {
      _followingBusy.remove(userId);
      return;
    }
    final original = _state.users[index];
    final following = !original.relationship.isFollowing;
    _replaceUser(
      index,
      original.withRelationship(
        UserRelationship(
          isFollowing: following,
          followsMe: original.relationship.followsMe,
          isFriend: following && original.relationship.followsMe,
        ),
      ),
    );
    try {
      _replaceUser(
        index,
        await _repository.setFollowing(userId, following: following),
      );
    } catch (error) {
      _replaceUser(index, original);
      _setState(_state.copyWith(errorMessage: error.toString()));
      rethrow;
    } finally {
      _followingBusy.remove(userId);
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) => _togglePost(
    postId,
    isLike: true,
    request: () => _repository.toggleLike(postId),
  );

  Future<void> toggleSave(String postId) => _togglePost(
    postId,
    isLike: false,
    request: () => _repository.toggleSave(postId),
  );

  Future<void> _togglePost(
    String postId, {
    required bool isLike,
    required Future<FeedMutation> Function() request,
  }) async {
    if (!_postBusy.add(postId)) return;
    final index = _state.posts.indexWhere((post) => post.id == postId);
    if (index < 0) {
      _postBusy.remove(postId);
      return;
    }
    final original = _state.posts[index];
    final active = isLike
        ? !original.viewerState.liked
        : !original.viewerState.saved;
    _replacePost(
      index,
      original.withInteraction(
        nextStats: PostStats(
          likes: isLike
              ? (original.stats.likes + (active ? 1 : -1)).clamp(0, 1 << 31)
              : original.stats.likes,
          comments: original.stats.comments,
          saves: isLike
              ? original.stats.saves
              : (original.stats.saves + (active ? 1 : -1)).clamp(0, 1 << 31),
        ),
        liked: isLike ? active : null,
        saved: isLike ? null : active,
      ),
    );
    try {
      final result = await request();
      final current = _state.posts.indexWhere((post) => post.id == postId);
      if (current >= 0) {
        _replacePost(
          current,
          _state.posts[current].withInteraction(
            nextStats: result.stats,
            liked: isLike ? result.active : null,
            saved: isLike ? null : result.active,
          ),
        );
      }
    } catch (error) {
      final current = _state.posts.indexWhere((post) => post.id == postId);
      if (current >= 0) _replacePost(current, original);
      _setState(_state.copyWith(errorMessage: error.toString()));
      rethrow;
    } finally {
      _postBusy.remove(postId);
      notifyListeners();
    }
  }

  void _replaceUser(int index, PublicUser user) {
    final users = [..._state.users]..[index] = user;
    _setState(_state.copyWith(users: users));
  }

  void _replacePost(int index, FeedPost post) {
    final posts = [..._state.posts]..[index] = post;
    _setState(_state.copyWith(posts: posts));
  }

  void _setState(SearchState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
