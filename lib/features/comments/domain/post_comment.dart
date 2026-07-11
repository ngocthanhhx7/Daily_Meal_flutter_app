class CommentAuthor {
  const CommentAuthor({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.themeColor,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    return CommentAuthor(
      id: rawId is String ? rawId : '',
      displayName: json['displayName'] as String? ?? 'Daily Meal',
      avatarUrl: json['avatarUrl'] as String?,
      themeColor: json['themeColor'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? themeColor;
}

class PostComment {
  const PostComment({
    required this.id,
    required this.body,
    required this.author,
    required this.createdAt,
    this.updatedAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final id = json['_id'];
    final body = json['body'];
    if (id is! String || id.isEmpty || body is! String || body.isEmpty) {
      throw const FormatException('Invalid comment payload');
    }
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (createdAt == null) throw const FormatException('Invalid comment date');
    return PostComment(
      id: id,
      body: body,
      author: CommentAuthor.fromJson(
        (json['author'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      createdAt: createdAt,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String body;
  final CommentAuthor author;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
