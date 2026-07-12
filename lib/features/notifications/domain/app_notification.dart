enum NotificationType { like, comment, follow, message }

enum NotificationDestination { home, inbox, publicProfile, comments, recipe }

class NotificationSender {
  const NotificationSender({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });
  factory NotificationSender.fromJson(Map<String, dynamic> json) =>
      NotificationSender(
        id: (json['id'] ?? json['_id']) as String,
        displayName: json['displayName'] as String? ?? 'Daily Meal',
        avatarUrl: json['avatarUrl'] as String?,
      );
  final String id;
  final String displayName;
  final String? avatarUrl;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.body,
    required this.read,
    required this.createdAt,
    this.sender,
    this.postId,
  });
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    final rawType = json['type'];
    final body = json['body'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        rawType is! String ||
        body is! String ||
        createdAt is! String) {
      throw const FormatException('Invalid notification');
    }
    return AppNotification(
      id: id,
      type: NotificationType.values.byName(rawType),
      body: body,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(createdAt),
      sender: json['sender'] is Map
          ? NotificationSender.fromJson(
              (json['sender'] as Map).cast<String, dynamic>(),
            )
          : null,
      postId: _id(json['post']),
    );
  }
  final String id;
  final NotificationType type;
  final String body;
  final bool read;
  final DateTime createdAt;
  final NotificationSender? sender;
  final String? postId;
  AppNotification withRead(bool value) => AppNotification(
    id: id,
    type: type,
    body: body,
    read: value,
    createdAt: createdAt,
    sender: sender,
    postId: postId,
  );
}

String? _id(Object? value) {
  if (value is String) return value;
  if (value is Map) return (value['id'] ?? value['_id']) as String?;
  return null;
}

NotificationDestination notificationDestination(AppNotification value) {
  if (value.type == NotificationType.follow && value.sender != null) {
    return NotificationDestination.publicProfile;
  }
  if (value.type == NotificationType.message) {
    return NotificationDestination.inbox;
  }
  if (value.postId != null && value.type == NotificationType.comment) {
    return NotificationDestination.comments;
  }
  if (value.postId != null && value.type == NotificationType.like) {
    return NotificationDestination.recipe;
  }
  return NotificationDestination.home;
}
