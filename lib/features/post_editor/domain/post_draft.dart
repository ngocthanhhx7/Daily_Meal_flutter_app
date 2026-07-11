import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';

enum DraftMediaType { image, video }

class UploadedMedia {
  const UploadedMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    required this.mime,
    required this.size,
    this.localPath,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) => UploadedMedia(
    id: _requiredString(json, '_id'),
    mediaType: DraftMediaType.values.byName(
      json['mediaType'] as String? ?? 'image',
    ),
    url: _requiredString(json, 'url'),
    localPath: json['localPath'] as String?,
    mime: json['mime'] as String? ?? '',
    size: (json['size'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final DraftMediaType mediaType;
  final String url;
  final String? localPath;
  final String mime;
  final int size;

  Map<String, dynamic> toImageJson() => {
    'url': url,
    if (localPath != null) 'localPath': localPath,
    'uploadId': id,
  };

  Map<String, dynamic> toVideoJson({int? durationMs}) => {
    'url': url,
    if (localPath != null) 'localPath': localPath,
    'uploadId': id,
    'mime': mime,
    'size': size,
    'durationMs': ?durationMs,
  };
}

class MealAnalysisResult {
  const MealAnalysisResult({
    required this.items,
    required this.total,
    required this.warnings,
  });

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) =>
      MealAnalysisResult(
        items: _maps(
          json['items'],
        ).map(NutritionItem.fromJson).toList(growable: false),
        total: NutritionSummary.fromJson(
          (json['total'] as Map).cast<String, dynamic>(),
        ),
        warnings: _strings(json['warnings']),
      );

  final List<NutritionItem> items;
  final NutritionSummary total;
  final List<String> warnings;
}

class MealAnalysis {
  const MealAnalysis({
    required this.id,
    required this.result,
    required this.createdAt,
  });

  factory MealAnalysis.fromJson(Map<String, dynamic> json) => MealAnalysis(
    id: _requiredString(json, '_id'),
    result: MealAnalysisResult.fromJson(
      (json['result'] as Map).cast<String, dynamic>(),
    ),
    createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
  );

  final String id;
  final MealAnalysisResult result;
  final DateTime createdAt;

  NutritionDetail toNutritionDetail(int imageIndex) => NutritionDetail(
    imageIndex: imageIndex,
    items: result.items,
    total: result.total,
    warnings: result.warnings,
    mealId: id,
  );
}

class StickerPlacement {
  const StickerPlacement({
    this.x = 0.78,
    this.y = 0.78,
    this.scale = 1,
    this.rotation = 0,
  });

  final double x;
  final double y;
  final double scale;
  final double rotation;

  Map<String, double> toJson() => {
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
  };
}

class PostDraft {
  const PostDraft({
    required this.mediaType,
    required this.images,
    required this.caption,
    required this.tags,
    required this.visibility,
    required this.layout,
    this.video,
    this.videoDurationMs,
    this.imageTransforms = const [],
    this.recipes = const [],
    this.nutritionDetails = const [],
    this.stickerId,
    this.stickerPlacement,
  });

  final DraftMediaType mediaType;
  final List<UploadedMedia> images;
  final UploadedMedia? video;
  final int? videoDurationMs;
  final List<PostImageTransform> imageTransforms;
  final String caption;
  final List<String> tags;
  final List<ImageRecipe> recipes;
  final List<NutritionDetail> nutritionDetails;
  final String? stickerId;
  final StickerPlacement? stickerPlacement;
  final PostVisibility visibility;
  final PostLayout layout;

  Map<String, dynamic> toJson() => {
    'mediaType': mediaType.name,
    'images': images.map((image) => image.toImageJson()).toList(),
    if (video != null) 'video': video!.toVideoJson(durationMs: videoDurationMs),
    'layout': layout.name,
    'imageTransforms': imageTransforms
        .map(
          (transform) => {
            'scale': transform.scale,
            'rotation': transform.rotation,
            'offsetX': transform.offsetX,
            'offsetY': transform.offsetY,
          },
        )
        .toList(),
    'caption': caption.trim(),
    'tags': tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(),
    'recipes': recipes
        .map(
          (recipe) => {
            'imageIndex': recipe.imageIndex,
            'title': recipe.title,
            'ingredients': recipe.ingredients,
            'steps': recipe.steps,
          },
        )
        .toList(),
    'nutritionDetails': nutritionDetails
        .map(
          (detail) => {
            'imageIndex': detail.imageIndex,
            'items': detail.items
                .map(
                  (item) => {
                    'name': item.name,
                    'portion': item.portion,
                    'calories': item.calories,
                    'protein': item.protein,
                    'carbs': item.carbs,
                    'fat': item.fat,
                    'confidence': item.confidence ?? 0,
                  },
                )
                .toList(),
            'total': {
              'calories': detail.total.calories,
              'protein': detail.total.protein,
              'carbs': detail.total.carbs,
              'fat': detail.total.fat,
              'confidence': detail.total.confidence ?? 0,
            },
            'warnings': detail.warnings,
            if (detail.mealId != null) 'mealId': detail.mealId,
          },
        )
        .toList(),
    if (stickerId != null) 'stickerId': stickerId,
    if (stickerPlacement != null)
      'stickerPlacement': stickerPlacement!.toJson(),
    'visibility': visibility.name,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing field: $key');
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
