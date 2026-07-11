import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/foundation.dart';

enum ProfileStatus { idle, loading, ready, failure }

enum ProfileTab { posts, saved }

enum ProfileImageKind { avatar, cover }

class ProfileState {
  const ProfileState({
    required this.status,
    required this.tab,
    required this.posts,
    required this.savedPosts,
    this.user,
    this.errorMessage,
    this.followBusy = false,
    this.profileBusy = false,
    this.safetyBusy = false,
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
  final bool profileBusy;
  final bool safetyBusy;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileTab? tab,
    PublicUser? user,
    List<FeedPost>? posts,
    List<FeedPost>? savedPosts,
    String? errorMessage,
    bool clearError = false,
    bool? followBusy,
    bool? profileBusy,
    bool? safetyBusy,
  }) => ProfileState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    user: user ?? this.user,
    posts: posts ?? this.posts,
    savedPosts: savedPosts ?? this.savedPosts,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    followBusy: followBusy ?? this.followBusy,
    profileBusy: profileBusy ?? this.profileBusy,
    safetyBusy: safetyBusy ?? this.safetyBusy,
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
    _set(_state.copyWith(profileBusy: true, clearError: true));
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
    } finally {
      _set(_state.copyWith(profileBusy: false));
    }
  }

  Future<void> updateProfileImage(
    PickedMedia media,
    ProfileImageKind kind,
  ) async {
    if (!isOwner) return;
    _set(_state.copyWith(profileBusy: true, clearError: true));
    try {
      final url = await _repository.uploadImage(
        bytes: media.bytes,
        fileName: media.fileName,
        mimeType: media.mimeType,
        category: kind.name,
      );
      _set(
        _state.copyWith(
          user: await _repository.updateMe({
            kind == ProfileImageKind.avatar ? 'avatarUrl' : 'coverUrl': url,
          }),
        ),
      );
    } catch (error) {
      _set(_state.copyWith(errorMessage: error.toString()));
      rethrow;
    } finally {
      _set(_state.copyWith(profileBusy: false));
    }
  }

  Future<void> setSafety(
    String type, {
    required bool active,
    String? note,
  }) async {
    final original = _state.user;
    if (isOwner || original == null || _state.safetyBusy) return;
    _set(
      _state.copyWith(
        safetyBusy: true,
        user: original.withViewerInteraction(
          ViewerInteraction(
            restricted: type == 'restrict'
                ? active
                : original.viewerInteraction.restricted,
            blocked: type == 'block'
                ? active
                : original.viewerInteraction.blocked,
            reported: type == 'report'
                ? active
                : original.viewerInteraction.reported,
          ),
        ),
      ),
    );
    try {
      final actual = await _repository.setInteraction(
        userId,
        type,
        active: active,
        note: note,
      );
      final current = _state.user!;
      _set(
        _state.copyWith(
          user: current.withViewerInteraction(
            ViewerInteraction(
              restricted: type == 'restrict'
                  ? actual
                  : current.viewerInteraction.restricted,
              blocked: type == 'block'
                  ? actual
                  : current.viewerInteraction.blocked,
              reported: type == 'report'
                  ? actual
                  : current.viewerInteraction.reported,
            ),
          ),
        ),
      );
    } catch (error) {
      _set(_state.copyWith(user: original, errorMessage: error.toString()));
      rethrow;
    } finally {
      _set(_state.copyWith(safetyBusy: false));
    }
  }

  void _set(ProfileState value) {
    _state = value;
    notifyListeners();
  }
}
