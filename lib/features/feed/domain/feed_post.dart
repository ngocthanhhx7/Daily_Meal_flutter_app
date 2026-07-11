enum PostMediaType { image, video }

enum PostLayout { stack, grid, cascade }

enum PostVisibility { public, friends, private }

class FeedAuthor {
  const FeedAuthor({
    required this.id,
    required this.displayName,
    required this.isPremium,
    required this.streakDays,
    this.avatarUrl,
    this.themeColor,
  });

  factory FeedAuthor.fromJson(Map<String, dynamic> json) => FeedAuthor(
    id: _requiredString(json, 'id'),
    displayName: _requiredString(json, 'displayName'),
    avatarUrl: json['avatarUrl'] as String?,
    isPremium: json['isPremium'] as bool? ?? false,
    streakDays: _integer(json['streakDays']),
    themeColor: json['themeColor'] as String?,
  );

  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isPremium;
  final int streakDays;
  final String? themeColor;
}

class PostImage {
  const PostImage({required this.url, this.localPath, this.uploadId});

  factory PostImage.fromJson(Map<String, dynamic> json) => PostImage(
    url: _requiredString(json, 'url'),
    localPath: json['localPath'] as String?,
    uploadId: json['uploadId'] as String?,
  );

  final String url;
  final String? localPath;
  final String? uploadId;
}

class PostVideo {
  const PostVideo({
    required this.url,
    this.localPath,
    this.uploadId,
    this.mime,
    this.size,
    this.durationMs,
  });

  factory PostVideo.fromJson(Map<String, dynamic> json) => PostVideo(
    url: _requiredString(json, 'url'),
    localPath: json['localPath'] as String?,
    uploadId: json['uploadId'] as String?,
    mime: json['mime'] as String?,
    size: _nullableInteger(json['size']),
    durationMs: _nullableInteger(json['durationMs']),
  );

  final String url;
  final String? localPath;
  final String? uploadId;
  final String? mime;
  final int? size;
  final int? durationMs;
}

class PostImageTransform {
  const PostImageTransform({
    required this.scale,
    required this.rotation,
    required this.offsetX,
    required this.offsetY,
  });

  factory PostImageTransform.fromJson(Map<String, dynamic> json) =>
      PostImageTransform(
        scale: _number(json['scale'], fallback: 1),
        rotation: _number(json['rotation']),
        offsetX: _number(json['offsetX']),
        offsetY: _number(json['offsetY']),
      );

  final double scale;
  final double rotation;
  final double offsetX;
  final double offsetY;
}

class PostRecipe {
  const PostRecipe({
    required this.ingredients,
    required this.steps,
    this.title,
  });

  factory PostRecipe.fromJson(Map<String, dynamic> json) => PostRecipe(
    title: json['title'] as String?,
    ingredients: _strings(json['ingredients']),
    steps: _strings(json['steps']),
  );

  final String? title;
  final List<String> ingredients;
  final List<String> steps;
}

class NutritionSummary {
  const NutritionSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.confidence,
  });

  factory NutritionSummary.fromJson(Map<String, dynamic> json) =>
      NutritionSummary(
        calories: _number(json['calories']),
        protein: _number(json['protein']),
        carbs: _number(json['carbs']),
        fat: _number(json['fat']),
        confidence: json['confidence'] is num
            ? (json['confidence'] as num).toDouble()
            : null,
      );

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? confidence;
}

class PostSticker {
  const PostSticker({
    required this.id,
    required this.key,
    required this.name,
    required this.assetPath,
    required this.premiumOnly,
  });

  factory PostSticker.fromJson(Map<String, dynamic> json) => PostSticker(
    id: _requiredString(json, '_id'),
    key: _requiredString(json, 'key'),
    name: _requiredString(json, 'name'),
    assetPath: _requiredString(json, 'assetPath'),
    premiumOnly: json['premiumOnly'] as bool? ?? false,
  );

  final String id;
  final String key;
  final String name;
  final String assetPath;
  final bool premiumOnly;
}

class PostStats {
  const PostStats({
    required this.likes,
    required this.comments,
    required this.saves,
  });

  factory PostStats.fromJson(Map<String, dynamic>? json) => PostStats(
    likes: _integer(json?['likes']),
    comments: _integer(json?['comments']),
    saves: _integer(json?['saves']),
  );

  final int likes;
  final int comments;
  final int saves;
}

class PostViewerState {
  const PostViewerState({required this.liked, required this.saved});

  factory PostViewerState.fromJson(Map<String, dynamic>? json) =>
      PostViewerState(
        liked: json?['liked'] as bool? ?? false,
        saved: json?['saved'] as bool? ?? false,
      );

  final bool liked;
  final bool saved;
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.mediaType,
    required this.images,
    required this.layout,
    required this.imageTransforms,
    required this.caption,
    required this.tags,
    required this.visibility,
    required this.stats,
    required this.viewerState,
    required this.createdAt,
    required this.updatedAt,
    this.video,
    this.recipe,
    this.nutritionSummary,
    this.sticker,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: _requiredString(json, '_id'),
      author: FeedAuthor.fromJson(_map(json['author'], 'author')),
      mediaType: _enumValue(
        PostMediaType.values,
        json['mediaType'] as String? ?? 'image',
        'mediaType',
      ),
      images: _maps(json['images']).map(PostImage.fromJson).toList(),
      video: json['video'] is Map
          ? PostVideo.fromJson((json['video'] as Map).cast<String, dynamic>())
          : null,
      layout: _enumValue(
        PostLayout.values,
        json['layout'] as String? ?? 'stack',
        'layout',
      ),
      imageTransforms: _maps(
        json['imageTransforms'],
      ).map(PostImageTransform.fromJson).toList(),
      caption: json['caption'] as String? ?? '',
      tags: _strings(json['tags']),
      recipe: json['recipe'] is Map
          ? PostRecipe.fromJson((json['recipe'] as Map).cast<String, dynamic>())
          : null,
      nutritionSummary: json['nutritionSummary'] is Map
          ? NutritionSummary.fromJson(
              (json['nutritionSummary'] as Map).cast<String, dynamic>(),
            )
          : null,
      sticker: json['stickerId'] is Map
          ? PostSticker.fromJson(
              (json['stickerId'] as Map).cast<String, dynamic>(),
            )
          : null,
      visibility: _enumValue(
        PostVisibility.values,
        json['visibility'] as String? ?? 'public',
        'visibility',
      ),
      stats: PostStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>(),
      ),
      viewerState: PostViewerState.fromJson(
        (json['viewerState'] as Map?)?.cast<String, dynamic>(),
      ),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
    );
  }

  final String id;
  final FeedAuthor author;
  final PostMediaType mediaType;
  final List<PostImage> images;
  final PostVideo? video;
  final PostLayout layout;
  final List<PostImageTransform> imageTransforms;
  final String caption;
  final List<String> tags;
  final PostRecipe? recipe;
  final NutritionSummary? nutritionSummary;
  final PostSticker? sticker;
  final PostVisibility visibility;
  final PostStats stats;
  final PostViewerState viewerState;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedPost withInteraction({
    required PostStats nextStats,
    bool? liked,
    bool? saved,
  }) => FeedPost(
    id: id,
    author: author,
    mediaType: mediaType,
    images: images,
    video: video,
    layout: layout,
    imageTransforms: imageTransforms,
    caption: caption,
    tags: tags,
    recipe: recipe,
    nutritionSummary: nutritionSummary,
    sticker: sticker,
    visibility: visibility,
    stats: nextStats,
    viewerState: PostViewerState(
      liked: liked ?? viewerState.liked,
      saved: saved ?? viewerState.saved,
    ),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

T _enumValue<T extends Enum>(List<T> values, String raw, String field) {
  try {
    return values.byName(raw);
  } on ArgumentError {
    throw FormatException('Unknown $field: $raw');
  }
}

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('Missing post field: $field');
}

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList()
    : const [];

List<String> _strings(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required field: $key');
}

DateTime _date(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed != null) return parsed;
  throw FormatException('Invalid post date: $key');
}

int _integer(Object? value) =>
    value is num ? value.toInt().clamp(0, 1 << 31) : 0;
int? _nullableInteger(Object? value) => value is num ? value.toInt() : null;
double _number(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : fallback;
