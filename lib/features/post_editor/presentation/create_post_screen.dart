import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_controller.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_providers.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:daily_meal_flutter_app/features/post_editor/services/media_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({
    this.controller,
    this.picker,
    this.onPublished,
    super.key,
  });

  static const captionKey = Key('post-caption');
  static const tagsKey = Key('post-tags');
  static const analyzeKey = Key('post-analyze');
  static const publishKey = Key('post-publish');

  final PostEditorController? controller;
  final MediaPickerService? picker;
  final ValueChanged<FeedPost>? onPublished;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _caption = TextEditingController();
  final _tags = TextEditingController();
  final _hints = TextEditingController();
  final _recipeTitle = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  String? _localError;

  PostEditorController get _controller =>
      widget.controller ?? ref.read(postEditorControllerProvider);
  MediaPickerService get _picker =>
      widget.picker ?? ref.read(mediaPickerServiceProvider);

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) widget.controller!.loadStickers();
  }

  @override
  void dispose() {
    _caption.dispose();
    _tags.dispose();
    _hints.dispose();
    _recipeTitle.dispose();
    _ingredients.dispose();
    _steps.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    await _guard(() async {
      final remaining = _controller.maxImages - _controller.state.media.length;
      if (remaining <= 0) throw StateError('Đã đạt giới hạn ảnh.');
      final files = await _picker.pickImages(limit: remaining);
      if (files.isNotEmpty) _controller.selectImages(files);
    });
  }

  Future<void> _capture() async {
    await _guard(() async {
      final file = await _picker.captureImage();
      if (file != null) _controller.selectImages([file]);
    });
  }

  Future<void> _pickVideo() async {
    await _guard(() async {
      final file = await _picker.pickVideo();
      if (file != null) _controller.selectVideo(file);
    });
  }

  Future<void> _analyze() async {
    await _guard(
      () => _controller.analyzeAll(
        hintsByImage: {
          for (var i = 0; i < _controller.state.media.length; i++)
            i: _hints.text,
        },
      ),
    );
  }

  Future<void> _publish() async {
    await _guard(() async {
      _syncTextState();
      final post = await _controller.publish();
      if (!mounted) return;
      if (widget.onPublished != null) {
        widget.onPublished!(post);
      } else {
        context.goNamed(AppRoute.home.name);
      }
    });
  }

  void _syncTextState() {
    _controller.updateCaption(_caption.text);
    _controller.updateTags(_tags.text);
    if (_controller.state.media.isNotEmpty) {
      _controller.updateRecipe(
        0,
        title: _recipeTitle.text,
        ingredients: _ingredients.text,
        steps: _steps.text,
      );
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      setState(() => _localError = null);
      await action();
    } catch (error) {
      if (mounted) setState(() => _localError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller case final provided?) {
      return AnimatedBuilder(
        animation: provided,
        builder: (context, _) => _buildBody(provided),
      );
    }
    return _buildBody(ref.watch(postEditorControllerProvider));
  }

  Widget _buildBody(PostEditorController controller) {
    final state = controller.state;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Tạo bài viết'),
        leading: BackButton(
          onPressed: () => widget.onPublished != null
              ? Navigator.maybePop(context)
              : context.goNamed(AppRoute.home.name),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StepHeader(step: state.step),
                const SizedBox(height: 16),
                if (state.media.isEmpty)
                  _CaptureCard(
                    isPremium: controller.isPremium,
                    onGallery: _pickImages,
                    onCamera: _capture,
                    onVideo: _pickVideo,
                  )
                else ...[
                  _MediaPreview(
                    state: state,
                    onRemove: controller.removeMedia,
                    onPlacementChanged: controller.updateStickerPlacement,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            key: CreatePostScreen.captionKey,
                            controller: _caption,
                            maxLength: 2000,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Chú thích',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: CreatePostScreen.tagsKey,
                            controller: _tags,
                            decoration: const InputDecoration(
                              labelText: 'Thẻ — tối đa 20',
                              hintText: '#healthy dinner',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<PostVisibility>(
                            initialValue: state.visibility,
                            decoration: const InputDecoration(
                              labelText: 'Quyền riêng tư',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: PostVisibility.public,
                                child: Text('Công khai'),
                              ),
                              DropdownMenuItem(
                                value: PostVisibility.friends,
                                child: Text('Bạn bè'),
                              ),
                              DropdownMenuItem(
                                value: PostVisibility.private,
                                child: Text('Riêng tư'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                controller.updateVisibility(value);
                              }
                            },
                          ),
                          if (state.media.length > 1) ...[
                            const SizedBox(height: 12),
                            SegmentedButton<PostLayout>(
                              segments: const [
                                ButtonSegment(
                                  value: PostLayout.stack,
                                  label: Text('Xếp chồng'),
                                ),
                                ButtonSegment(
                                  value: PostLayout.grid,
                                  label: Text('Lưới'),
                                ),
                                ButtonSegment(
                                  value: PostLayout.cascade,
                                  label: Text('So le'),
                                ),
                              ],
                              selected: {state.layout},
                              onSelectionChanged: (selection) =>
                                  controller.updateLayout(selection.first),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnalysisCard(
                    hints: _hints,
                    state: state,
                    onAnalyze: _analyze,
                  ),
                  const SizedBox(height: 16),
                  _RecipeCard(
                    title: _recipeTitle,
                    ingredients: _ingredients,
                    steps: _steps,
                  ),
                  const SizedBox(height: 16),
                  _StickerCard(state: state, controller: controller),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: CreatePostScreen.publishKey,
                    onPressed: state.isBusy ? null : _publish,
                    icon: state.isBusy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: const Text('Đăng bài'),
                  ),
                ],
                if (_localError ?? state.errorMessage case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final PostEditorStep step;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final value in PostEditorStep.values) ...[
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: value.index <= step.index
                    ? AppColors.greenDark
                    : AppColors.line,
                child: Text(
                  '${value.index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(switch (value) {
                PostEditorStep.capture => 'Chọn media',
                PostEditorStep.edit => 'Nội dung',
                PostEditorStep.sticker => 'Nhãn dán',
              }),
            ],
          ),
        ),
      ],
    ],
  );
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.isPremium,
    required this.onGallery,
    required this.onCamera,
    required this.onVideo,
  });
  final bool isPremium;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.add_photo_alternate_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            isPremium ? 'Chọn tối đa 3 ảnh hoặc 1 video' : 'Chọn 1 ảnh',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh'),
              ),
              FilledButton.tonalIcon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp ảnh'),
              ),
              FilledButton.tonalIcon(
                onPressed: isPremium ? onVideo : null,
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Chọn video'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.state,
    required this.onRemove,
    required this.onPlacementChanged,
  });
  final PostEditorState state;
  final ValueChanged<int> onRemove;
  final ValueChanged<StickerPlacement> onPlacementChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.media.first.mediaType == DraftMediaType.video)
            const AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: Colors.black12,
                child: Center(child: Icon(Icons.videocam_rounded, size: 56)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        state.media.first.bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: AppColors.canvasStrong,
                              child: Center(child: Icon(Icons.image_outlined)),
                            ),
                      ),
                    ),
                    if (state.selectedStickerId != null)
                      Positioned(
                        left:
                            state.stickerPlacement.x * constraints.maxWidth -
                            30,
                        top:
                            state.stickerPlacement.y *
                                (constraints.maxWidth * 0.75) -
                            30,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final height = constraints.maxWidth * 0.75;
                            onPlacementChanged(
                              StickerPlacement(
                                x:
                                    (state.stickerPlacement.x +
                                            details.delta.dx /
                                                constraints.maxWidth)
                                        .clamp(0, 1),
                                y:
                                    (state.stickerPlacement.y +
                                            details.delta.dy / height)
                                        .clamp(0, 1),
                                scale: state.stickerPlacement.scale,
                                rotation: state.stickerPlacement.rotation,
                              ),
                            );
                          },
                          child: Transform.rotate(
                            angle:
                                state.stickerPlacement.rotation *
                                3.1415926 /
                                180,
                            child: Transform.scale(
                              scale: state.stickerPlacement.scale,
                              child: const Chip(label: Text('Sticker')),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          for (var index = 0; index < state.media.length; index++)
            ListTile(
              dense: true,
              leading: Icon(
                state.media[index].mediaType == DraftMediaType.video
                    ? Icons.movie_outlined
                    : Icons.image_outlined,
              ),
              title: Text(state.media[index].fileName),
              subtitle: Text(
                '${(state.media[index].bytes.length / 1024).ceil()} KB',
              ),
              trailing: IconButton(
                tooltip: 'Xóa media',
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
        ],
      ),
    ),
  );
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.hints,
    required this.state,
    required this.onAnalyze,
  });
  final TextEditingController hints;
  final PostEditorState state;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dinh dưỡng AI', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: hints,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Gợi ý nguyên liệu (không bắt buộc)',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton.tonalIcon(
            key: CreatePostScreen.analyzeKey,
            onPressed: state.isBusy ? null : onAnalyze,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Phân tích AI'),
          ),
          for (final detail in state.nutritionDetails)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Ảnh ${detail.imageIndex + 1}: '
                '${detail.total.calories.round()} kcal • '
                'Protein ${detail.total.protein.round()}g',
              ),
            ),
        ],
      ),
    ),
  );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.title,
    required this.ingredients,
    required this.steps,
  });
  final TextEditingController title;
  final TextEditingController ingredients;
  final TextEditingController steps;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: const Text('Công thức cho ảnh 1'),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: [
        TextField(
          controller: title,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Tên món'),
        ),
        TextField(
          controller: ingredients,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Nguyên liệu — mỗi dòng một mục',
          ),
        ),
        TextField(
          controller: steps,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Các bước — mỗi dòng một bước',
          ),
        ),
      ],
    ),
  );
}

class _StickerCard extends StatelessWidget {
  const _StickerCard({required this.state, required this.controller});
  final PostEditorState state;
  final PostEditorController controller;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nhãn dán', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Không dùng'),
                selected: state.selectedStickerId == null,
                onSelected: (_) => controller.selectSticker(null),
              ),
              for (final sticker in state.stickers)
                ChoiceChip(
                  label: Text(sticker.name),
                  selected: state.selectedStickerId == sticker.id,
                  onSelected: (_) => controller.selectSticker(sticker.id),
                ),
            ],
          ),
          if (state.selectedStickerId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Kích thước ${state.stickerPlacement.scale.toStringAsFixed(1)}',
            ),
            Slider(
              value: state.stickerPlacement.scale,
              min: 0.5,
              max: 2,
              onChanged: (value) => controller.updateStickerPlacement(
                StickerPlacement(
                  x: state.stickerPlacement.x,
                  y: state.stickerPlacement.y,
                  scale: value,
                  rotation: state.stickerPlacement.rotation,
                ),
              ),
            ),
            Text('Xoay ${state.stickerPlacement.rotation.round()}°'),
            Slider(
              value: state.stickerPlacement.rotation,
              min: -180,
              max: 180,
              onChanged: (value) => controller.updateStickerPlacement(
                StickerPlacement(
                  x: state.stickerPlacement.x,
                  y: state.stickerPlacement.y,
                  scale: state.stickerPlacement.scale,
                  rotation: value,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
