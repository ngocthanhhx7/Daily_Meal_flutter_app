enum BirthdayVisibility { hidden, dayMonth, full }

class UserBirthday {
  const UserBirthday({this.date, required this.visibility});

  factory UserBirthday.fromJson(Map<String, dynamic> json) {
    final rawVisibility = json['visibility'] as String? ?? 'hidden';
    BirthdayVisibility visibility;
    try {
      visibility = BirthdayVisibility.values.byName(rawVisibility);
    } on ArgumentError {
      throw FormatException('Unknown birthday visibility: $rawVisibility');
    }
    return UserBirthday(date: json['date'] as String?, visibility: visibility);
  }

  final String? date;
  final BirthdayVisibility visibility;
}

class UserPreferences {
  const UserPreferences({
    required this.interests,
    required this.eatingStyles,
    required this.completedOnboarding,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        interests: _stringList(json['interests']),
        eatingStyles: _stringList(json['eatingStyles']),
        completedOnboarding: json['completedOnboarding'] as bool? ?? false,
      );

  final List<String> interests;
  final List<String> eatingStyles;
  final bool completedOnboarding;

  static List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];
}

class UserCounts {
  const UserCounts({
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.friends = 0,
  });

  factory UserCounts.fromJson(Map<String, dynamic>? json) => UserCounts(
    posts: _nonNegative(json?['posts']),
    followers: _nonNegative(json?['followers']),
    following: _nonNegative(json?['following']),
    friends: _nonNegative(json?['friends']),
  );

  final int posts;
  final int followers;
  final int following;
  final int friends;

  static int _nonNegative(Object? value) =>
      value is num ? value.toInt().clamp(0, 1 << 31) : 0;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.isPremium,
    required this.preferences,
    required this.counts,
    this.email,
    this.phone,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.birthday,
    this.premiumTrialUsed = false,
    this.premiumTrialStartedAt,
    this.premiumTrialEndsAt,
    this.premiumPaidEndsAt,
    this.streakDays = 0,
    this.themeColor,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: _requiredString(json, 'id'),
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    displayName: _requiredString(json, 'displayName'),
    avatarUrl: json['avatarUrl'] as String?,
    coverUrl: json['coverUrl'] as String?,
    bio: json['bio'] as String?,
    birthday: json['birthday'] is Map<String, dynamic>
        ? UserBirthday.fromJson(json['birthday'] as Map<String, dynamic>)
        : null,
    isPremium: json['isPremium'] as bool? ?? false,
    premiumTrialUsed: json['premiumTrialUsed'] as bool? ?? false,
    premiumTrialStartedAt: _date(json['premiumTrialStartedAt']),
    premiumTrialEndsAt: _date(json['premiumTrialEndsAt']),
    premiumPaidEndsAt: _date(json['premiumPaidEndsAt']),
    streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
    themeColor: json['themeColor'] as String?,
    preferences: UserPreferences.fromJson(
      (json['preferences'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    counts: UserCounts.fromJson(
      (json['counts'] as Map?)?.cast<String, dynamic>(),
    ),
  );

  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final UserBirthday? birthday;
  final bool isPremium;
  final bool premiumTrialUsed;
  final DateTime? premiumTrialStartedAt;
  final DateTime? premiumTrialEndsAt;
  final DateTime? premiumPaidEndsAt;
  final int streakDays;
  final String? themeColor;
  final UserPreferences preferences;
  final UserCounts counts;

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing required user field: $key');
    }
    return value;
  }

  static DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
}
