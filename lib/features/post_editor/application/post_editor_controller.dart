import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:flutter/foundation.dart';

enum PostEditorStep { capture, edit, sticker }

class RecipeDraft {
  const RecipeDraft({this.title = '', this.ingredients = '', this.steps = ''});
  final String title;
  final String ingredients;
  final String steps;
}

class PostEditorState {
  const PostEditorState({
    required this.step,
    required this.media,
    required this.caption,
    required this.tagsText,
    required this.visibility,
    required this.layout,
    required this.recipes,
    required this.nutritionDetails,
    required this.stickers,
    required this.stickerPlacement,
    this.selectedStickerId,
    this.isBusy = false,
    this.errorMessage,
  });

  const PostEditorState.initial()
    : this(
        step: PostEditorStep.capture,
        media: const [],
        caption: '',
        tagsText: '',
        visibility: PostVisibility.public,
        layout: PostLayout.stack,
        recipes: const {},
        nutritionDetails: const [],
        stickers: const [],
        stickerPlacement: const StickerPlacement(),
      );

  final PostEditorStep step;
  final List<PickedMedia> media;
  final String caption;
  final String tagsText;
  final PostVisibility visibility;
  final PostLayout layout;
  final Map<int, RecipeDraft> recipes;
  final List<NutritionDetail> nutritionDetails;
  final List<PostSticker> stickers;
  final String? selectedStickerId;
  final StickerPlacement stickerPlacement;
  final bool isBusy;
  final String? errorMessage;

  PostEditorState copyWith({
    PostEditorStep? step,
    List<PickedMedia>? media,
    String? caption,
    String? tagsText,
    PostVisibility? visibility,
    PostLayout? layout,
    Map<int, RecipeDraft>? recipes,
    List<NutritionDetail>? nutritionDetails,
    List<PostSticker>? stickers,
    String? selectedStickerId,
    StickerPlacement? stickerPlacement,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    bool clearSticker = false,
  }) => PostEditorState(
    step: step ?? this.step,
    media: media ?? this.media,
    caption: caption ?? this.caption,
    tagsText: tagsText ?? this.tagsText,
    visibility: visibility ?? this.visibility,
    layout: layout ?? this.layout,
    recipes: recipes ?? this.recipes,
    nutritionDetails: nutritionDetails ?? this.nutritionDetails,
    stickers: stickers ?? this.stickers,
    selectedStickerId: clearSticker
        ? null
        : selectedStickerId ?? this.selectedStickerId,
    stickerPlacement: stickerPlacement ?? this.stickerPlacement,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class PostEditorController extends ChangeNotifier {
  PostEditorController(this._repository, {required this.isPremium});

  final PostEditorRepositoryContract _repository;
  final bool isPremium;
  PostEditorState _state = const PostEditorState.initial();
  final Map<PickedMedia, UploadedMedia> _uploads = {};

  PostEditorState get state => _state;
  int get maxImages => isPremium ? 3 : 1;

  void selectImages(List<PickedMedia> images) {
    if (images.any((item) => item.mediaType != DraftMediaType.image)) {
      throw StateError('Only images can be added to an image draft.');
    }
    final unique = [..._state.media];
    for (final image in images) {
      if (!unique.any((item) => item.fileName == image.fileName)) {
        unique.add(image);
      }
    }
    if (unique.length > maxImages) {
      throw StateError(
        isPremium
            ? 'Tối đa 3 ảnh cho mỗi bài viết.'
            : 'Tài khoản miễn phí chỉ được chọn 1 ảnh.',
      );
    }
    _setState(
      _state.copyWith(
        media: unique,
        step: PostEditorStep.edit,
        nutritionDetails: const [],
        clearError: true,
      ),
    );
  }

  void selectVideo(PickedMedia video) {
    if (!isPremium) throw StateError('Video yêu cầu tài khoản Premium.');
    if (video.mediaType != DraftMediaType.video) {
      throw StateError('Selected file is not a video.');
    }
    _uploads.clear();
    _setState(
      _state.copyWith(
        media: [video],
        step: PostEditorStep.edit,
        nutritionDetails: const [],
        clearError: true,
      ),
    );
  }

  void removeMedia(int index) {
    if (index < 0 || index >= _state.media.length) return;
    final next = [..._state.media];
    final removed = next.removeAt(index);
    _uploads.remove(removed);
    _setState(
      _state.copyWith(
        media: next,
        step: next.isEmpty ? PostEditorStep.capture : _state.step,
        nutritionDetails: const [],
      ),
    );
  }

  void updateCaption(String value) {
    if (value.length > 2000) throw StateError('Caption tối đa 2000 ký tự.');
    _setState(_state.copyWith(caption: value));
  }

  void updateTags(String value) => _setState(_state.copyWith(tagsText: value));
  void updateVisibility(PostVisibility value) =>
      _setState(_state.copyWith(visibility: value));
  void updateLayout(PostLayout value) =>
      _setState(_state.copyWith(layout: value));

  void updateRecipe(
    int imageIndex, {
    required String title,
    required String ingredients,
    required String steps,
  }) {
    if (title.length > 120) throw StateError('Tên công thức tối đa 120 ký tự.');
    _setState(
      _state.copyWith(
        recipes: {
          ..._state.recipes,
          imageIndex: RecipeDraft(
            title: title,
            ingredients: ingredients,
            steps: steps,
          ),
        },
      ),
    );
  }

  void selectSticker(String? id) => _setState(
    _state.copyWith(
      selectedStickerId: id,
      clearSticker: id == null,
      step: PostEditorStep.sticker,
    ),
  );

  void updateStickerPlacement(StickerPlacement placement) {
    if (placement.x < 0 ||
        placement.x > 1 ||
        placement.y < 0 ||
        placement.y > 1 ||
        placement.scale < 0.5 ||
        placement.scale > 2 ||
        placement.rotation < -180 ||
        placement.rotation > 180) {
      throw StateError('Sticker placement is outside server bounds.');
    }
    _setState(_state.copyWith(stickerPlacement: placement));
  }

  Future<void> loadStickers() async {
    try {
      _setState(_state.copyWith(stickers: await _repository.stickers()));
    } catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> analyzeAll({Map<int, String> hintsByImage = const {}}) async {
    final images = _state.media
        .where((item) => item.mediaType == DraftMediaType.image)
        .toList();
    if (images.isEmpty) throw StateError('Chọn ảnh trước khi phân tích.');
    _setState(_state.copyWith(isBusy: true, clearError: true));
    try {
      final details = <NutritionDetail>[];
      for (var index = 0; index < images.length; index++) {
        final upload = await _ensureUploaded(images[index]);
        final analysis = await _repository.analyze(
          upload,
          hints: hintsByImage[index],
        );
        details.add(analysis.toNutritionDetail(index));
      }
      _setState(_state.copyWith(nutritionDetails: details, isBusy: false));
    } catch (error) {
      _setState(_state.copyWith(isBusy: false, errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<FeedPost> publish() async {
    if (_state.media.isEmpty) throw StateError('Chọn ảnh hoặc video để đăng.');
    _setState(_state.copyWith(isBusy: true, clearError: true));
    try {
      final uploaded = <UploadedMedia>[];
      for (final media in _state.media) {
        uploaded.add(await _ensureUploaded(media));
      }
      final videoDraft = _state.media.first.mediaType == DraftMediaType.video;
      final draft = PostDraft(
        mediaType: videoDraft ? DraftMediaType.video : DraftMediaType.image,
        images: videoDraft ? const [] : uploaded,
        video: videoDraft ? uploaded.single : null,
        videoDurationMs: videoDraft ? _state.media.single.durationMs : null,
        imageTransforms: videoDraft
            ? const []
            : List.generate(
                uploaded.length,
                (_) => const PostImageTransform(
                  scale: 1,
                  rotation: 0,
                  offsetX: 0,
                  offsetY: 0,
                ),
              ),
        caption: _state.caption,
        tags: _normalizedTags(_state.tagsText),
        recipes: _recipes(),
        nutritionDetails: _state.nutritionDetails,
        stickerId: _state.selectedStickerId,
        stickerPlacement: _state.selectedStickerId == null
            ? null
            : _state.stickerPlacement,
        visibility: _state.visibility,
        layout: _state.layout,
      );
      final post = await _repository.publish(draft);
      _setState(_state.copyWith(isBusy: false));
      return post;
    } catch (error) {
      _setState(_state.copyWith(isBusy: false, errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<UploadedMedia> _ensureUploaded(PickedMedia media) async {
    final existing = _uploads[media];
    if (existing != null) return existing;
    final uploaded = await _repository.upload(media);
    _uploads[media] = uploaded;
    return uploaded;
  }

  List<String> _normalizedTags(String raw) => raw
      .split(RegExp(r'[\s,]+'))
      .map((tag) => tag.replaceFirst(RegExp(r'^#'), '').trim().toLowerCase())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .take(20)
      .toList(growable: false);

  List<ImageRecipe> _recipes() => _state.recipes.entries
      .where(
        (entry) =>
            entry.value.title.trim().isNotEmpty ||
            entry.value.ingredients.trim().isNotEmpty ||
            entry.value.steps.trim().isNotEmpty,
      )
      .map(
        (entry) => ImageRecipe(
          imageIndex: entry.key,
          title: entry.value.title.trim(),
          ingredients: _lines(entry.value.ingredients),
          steps: _lines(entry.value.steps),
        ),
      )
      .toList(growable: false);

  List<String> _lines(String raw) => raw
      .split(RegExp(r'[\r\n]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  void _setState(PostEditorState next) {
    _state = next;
    notifyListeners();
  }
}
