enum PostSummaryFilter {
  all('all', 'Tất cả'),
  friends('friends', 'Bạn bè'),
  following('following', 'Đang theo dõi'),
  strangers('strangers', 'Người lạ');

  const PostSummaryFilter(this.wireValue, this.label);
  final String wireValue, label;
}

class SummaryPost {
  const SummaryPost({
    required this.id,
    required this.caption,
    required this.authorName,
    required this.likes,
    required this.comments,
    this.imageUrl,
  });
  factory SummaryPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'] is Map ? json['author'] as Map : const {};
    final stats = json['stats'] is Map ? json['stats'] as Map : const {};
    final images = json['images'] is List ? json['images'] as List : const [];
    final image = images.whereType<Map>().firstOrNull;
    return SummaryPost(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      caption: json['caption']?.toString() ?? '',
      authorName: author['displayName']?.toString() ?? 'Daily Meal',
      likes: _int(stats['likes']),
      comments: _int(stats['comments']),
      imageUrl: image?['url']?.toString(),
    );
  }
  static int _int(Object? value) => value is num ? value.round() : 0;
  final String id, caption, authorName;
  final int likes, comments;
  final String? imageUrl;
}

class PostSummaryPage {
  const PostSummaryPage({
    required this.posts,
    required this.page,
    required this.hasMore,
  });
  factory PostSummaryPage.fromJson(Map<String, dynamic> json) =>
      PostSummaryPage(
        posts: (json['posts'] is List ? json['posts'] as List : const [])
            .whereType<Map>()
            .map((e) => SummaryPost.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
        page: json['page'] is num ? (json['page'] as num).round() : 1,
        hasMore: json['hasMore'] == true,
      );
  final List<SummaryPost> posts;
  final int page;
  final bool hasMore;
}
