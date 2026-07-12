import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_providers.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  const EditPostScreen({
    required this.post,
    this.repository,
    this.mediaResolver,
    this.onUpdated,
    this.onDeleted,
    super.key,
  });

  static const captionKey = Key('edit-post-caption');
  static const tagsKey = Key('edit-post-tags');
  static const saveKey = Key('edit-post-save');
  static const deleteKey = Key('edit-post-delete');

  final FeedPost post;
  final PostManagementRepositoryContract? repository;
  final MediaUrlResolver? mediaResolver;
  final ValueChanged<FeedPost>? onUpdated;
  final ValueChanged<String>? onDeleted;

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late final TextEditingController _caption;
  late final TextEditingController _tags;
  bool _busy = false;
  String? _error;

  PostManagementRepositoryContract get _repository =>
      widget.repository ?? ref.read(postManagementRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(text: widget.post.caption);
    _tags = TextEditingController(text: widget.post.tags.join(', '));
  }

  @override
  void dispose() {
    _caption.dispose();
    _tags.dispose();
    super.dispose();
  }

  List<String> _normalizedTags() => _tags.text
      .split(RegExp(r'[\s,]+'))
      .map((tag) => tag.replaceFirst(RegExp(r'^#'), '').trim().toLowerCase())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .take(20)
      .toList(growable: false);

  Future<void> _save() async {
    if (_caption.text.length > 2000) {
      setState(() => _error = 'Chú thích tối đa 2000 ký tự.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await _repository.update(
        widget.post.id,
        caption: _caption.text,
        tags: _normalizedTags(),
      );
      if (mounted) widget.onUpdated?.call(updated);
    } catch (error) {
      if (mounted) setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text(
          'Bài viết, bình luận, lượt thích và lượt lưu liên quan sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.delete(widget.post.id);
      if (mounted) widget.onDeleted?.call(widget.post.id);
    } catch (error) {
      if (mounted) setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chỉnh sửa nội dung',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: EditPostScreen.captionKey,
                  controller: _caption,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: EditPostScreen.tagsKey,
                  controller: _tags,
                  decoration: const InputDecoration(labelText: 'Tags'),
                ),
                if (_error case final message?) ...[
                  const SizedBox(height: 10),
                  Text(message, style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.pop(sheetContext),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: EditPostScreen.saveKey,
                        onPressed: _busy
                            ? null
                            : () async {
                                await _save();
                                if (sheetContext.mounted && _error == null) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                        child: const Text('Lưu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaUrlResolver resolver;
    if (widget.mediaResolver case final provided?) {
      resolver = provided;
    } else {
      resolver = ref.watch(mediaUrlResolverProvider);
    }
    final hasRecipe =
        widget.post.recipe != null || widget.post.recipes.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: DailyMealBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.black,
                          child: Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Bài viết',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _PostPreview(post: widget.post, resolver: resolver),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 350),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: .94),
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.post.caption.isNotEmpty
                                ? widget.post.caption
                                : widget.post.recipe?.title ??
                                      'Bài viết Daily Meal',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.post.createdAt.day}/${widget.post.createdAt.month}/${widget.post.createdAt.year} · ${widget.post.visibility.name}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ActionRow(
                    icon: Icons.explore_outlined,
                    title: 'Xem trong bảng tin',
                    subtitle: 'Mở đúng bài đăng này trong luồng bảng tin',
                    onTap: () => context.goNamed(
                      AppRoute.home.name,
                      queryParameters: {'postId': widget.post.id},
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionRow(
                    icon: Icons.edit_outlined,
                    title: 'Chỉnh sửa nội dung',
                    subtitle: 'Sửa mô tả và thẻ của bài viết',
                    onTap: _openEditSheet,
                  ),
                  if (hasRecipe) ...[
                    const SizedBox(height: 10),
                    _ActionRow(
                      icon: Icons.restaurant_outlined,
                      title: 'Xem công thức',
                      subtitle: 'Mở phần công thức đã gắn với bài',
                      onTap: () => context.pushNamed(
                        AppRoute.recipe.name,
                        pathParameters: {'id': widget.post.id},
                        queryParameters: {'authorId': widget.post.author.id},
                        extra: widget.post,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _ActionRow(
                    key: EditPostScreen.deleteKey,
                    icon: Icons.delete_outline,
                    title: 'Xóa bài viết',
                    subtitle: 'Gỡ bài này khỏi hồ sơ của bạn',
                    danger: true,
                    onTap: _busy ? null : _confirmDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.post, required this.resolver});
  final FeedPost post;
  final MediaUrlResolver resolver;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 270,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (post.images.length > 2)
          Transform.rotate(
            angle: -.07,
            child: _PreviewImage(
              uri: resolver.resolve(post.images[2].url),
              opacity: .72,
            ),
          ),
        if (post.images.length > 1)
          Transform.rotate(
            angle: .07,
            child: _PreviewImage(
              uri: resolver.resolve(post.images[1].url),
              opacity: .86,
            ),
          ),
        SizedBox(
          width: 210,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PostMedia(
              post: post,
              resolver: resolver,
              onDoubleTapLike: () {},
            ),
          ),
        ),
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0x6B000000),
          child: Icon(Icons.camera_alt, size: 18, color: AppColors.white),
        ),
      ],
    ),
  );
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.uri, required this.opacity});
  final Uri? uri;
  final double opacity;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Container(
      width: 210,
      height: 270,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.canvasStrong,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: uri == null
          ? null
          : Image.network(uri.toString(), fit: BoxFit.cover),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFFEEEE)
                    : AppColors.canvasStrong,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: danger ? AppColors.red : AppColors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: danger ? AppColors.red : AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
