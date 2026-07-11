class PublicUserCounts {
  const PublicUserCounts({
    required this.posts,
    required this.followers,
    required this.following,
    required this.friends,
  });

  factory PublicUserCounts.fromJson(Map<String, dynamic>? json) =>
      PublicUserCounts(
        posts: _integer(json?['posts']),
        followers: _integer(json?['followers']),
        following: _integer(json?['following']),
        friends: _integer(json?['friends']),
      );

  final int posts;
  final int followers;
  final int following;
  final int friends;
}

class UserRelationship {
  const UserRelationship({
    required this.isFollowing,
    required this.followsMe,
    required this.isFriend,
  });

  factory UserRelationship.fromJson(Map<String, dynamic>? json) =>
      UserRelationship(
        isFollowing: json?['isFollowing'] as bool? ?? false,
        followsMe: json?['followsMe'] as bool? ?? false,
        isFriend: json?['isFriend'] as bool? ?? false,
      );

  final bool isFollowing;
  final bool followsMe;
  final bool isFriend;
}

class ViewerInteraction {
  const ViewerInteraction({
    required this.restricted,
    required this.blocked,
    required this.reported,
  });

  factory ViewerInteraction.fromJson(Map<String, dynamic>? json) =>
      ViewerInteraction(
        restricted: json?['restricted'] as bool? ?? false,
        blocked: json?['blocked'] as bool? ?? false,
        reported: json?['reported'] as bool? ?? false,
      );

  final bool restricted;
  final bool blocked;
  final bool reported;
}

class PublicUser {
  const PublicUser({
    required this.id,
    required this.displayName,
    required this.isPremium,
    required this.counts,
    required this.relationship,
    required this.viewerInteraction,
    this.email,
    this.phone,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.streakDays = 0,
    this.themeColor,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final displayName = json['displayName'];
    if (rawId is! String || rawId.isEmpty || displayName is! String) {
      throw const FormatException('Invalid public user payload');
    }
    return PublicUser(
      id: rawId,
      displayName: displayName,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      bio: json['bio'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      streakDays: _integer(json['streakDays']),
      themeColor: json['themeColor'] as String?,
      counts: PublicUserCounts.fromJson(
        (json['counts'] as Map?)?.cast<String, dynamic>(),
      ),
      relationship: UserRelationship.fromJson(
        (json['relationship'] as Map?)?.cast<String, dynamic>(),
      ),
      viewerInteraction: ViewerInteraction.fromJson(
        (json['viewerInteraction'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final bool isPremium;
  final int streakDays;
  final String? themeColor;
  final PublicUserCounts counts;
  final UserRelationship relationship;
  final ViewerInteraction viewerInteraction;

  PublicUser withRelationship(UserRelationship next) => PublicUser(
    id: id,
    email: email,
    phone: phone,
    displayName: displayName,
    avatarUrl: avatarUrl,
    coverUrl: coverUrl,
    bio: bio,
    isPremium: isPremium,
    streakDays: streakDays,
    themeColor: themeColor,
    counts: counts,
    relationship: next,
    viewerInteraction: viewerInteraction,
  );
}

int _integer(Object? value) =>
    value is num ? value.toInt().clamp(0, 1 << 31) : 0;
