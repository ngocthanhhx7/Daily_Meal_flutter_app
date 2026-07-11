import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/foundation.dart';

enum ProfileStatus { idle, loading, ready, failure }

enum ProfileTab { posts, saved }

class ProfileState {
  const ProfileState({
    required this.status,
    required this.tab,
    required this.posts,
    required this.savedPosts,
    this.user,
    this.errorMessage,
    this.followBusy = false,
  });

  const ProfileState.initial()
    : this(
        status: ProfileStatus.idle,
        tab: ProfileTab.posts,
        posts: const [],
        savedPosts: const [],
      );

  final ProfileStatus status;
  final ProfileTab tab;
  final PublicUser? user;
  final List<FeedPost> posts;
  final List<FeedPost> savedPosts;
  final String? errorMessage;
  final bool followBusy;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileTab? tab,
    PublicUser? user,
    List<FeedPost>? posts,
    List<FeedPost>? savedPosts,
    String? errorMessage,
    bool clearError = false,
    bool? followBusy,
  }) => ProfileState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    user: user ?? this.user,
    posts: posts ?? this.posts,
    savedPosts: savedPosts ?? this.savedPosts,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    followBusy: followBusy ?? this.followBusy,
  );
}

class ProfileController extends ChangeNotifier {
  ProfileController(
    this._repository, {
    required this.userId,
    required this.isOwner,
  });
  final ProfileRepositoryContract _repository;
  final String userId;
  final bool isOwner;
  ProfileState _state = const ProfileState.initial();
  ProfileState get state => _state;

  Future<void> load() async {
    _set(_state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final bundle = await _repository.loadProfile(
        userId,
        includeSaved: isOwner,
      );
      _set(
        _state.copyWith(
          status: ProfileStatus.ready,
          user: bundle.user,
          posts: bundle.posts,
          savedPosts: bundle.savedPosts,
        ),
      );
    } catch (error) {
      _set(
        _state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  void selectTab(ProfileTab tab) {
    if (tab == ProfileTab.saved && !isOwner) return;
    _set(_state.copyWith(tab: tab));
  }

  Future<List<PublicUser>> loadFollows({required bool followers}) =>
      _repository.loadFollows(userId, followers: followers);

  Future<void> toggleFollow() async {
    final original = _state.user;
    if (isOwner || original == null || _state.followBusy) return;
    final following = !original.relationship.isFollowing;
    _set(
      _state.copyWith(
        followBusy: true,
        user: original.withRelationship(
          UserRelationship(
            isFollowing: following,
            followsMe: original.relationship.followsMe,
            isFriend: following && original.relationship.followsMe,
          ),
        ),
      ),
    );
    try {
      _set(
        _state.copyWith(
          user: await _repository.setFollowing(userId, following: following),
        ),
      );
    } catch (error) {
      _set(_state.copyWith(user: original, errorMessage: error.toString()));
      rethrow;
    } finally {
      _set(_state.copyWith(followBusy: false));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> changes) async {
    if (!isOwner) return;
    try {
      _set(
        _state.copyWith(
          user: await _repository.updateMe(changes),
          clearError: true,
        ),
      );
    } catch (error) {
      _set(_state.copyWith(errorMessage: error.toString()));
      rethrow;
    }
  }

  void _set(ProfileState value) {
    _state = value;
    notifyListeners();
  }
}
