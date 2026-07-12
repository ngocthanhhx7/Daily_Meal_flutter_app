import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_media.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_providers.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final MediaUrlResolver resolver;
    if (widget.mediaResolver case final provided?) {
      resolver = provided;
    } else {
      resolver = ref.watch(mediaUrlResolverProvider);
    }
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Chỉnh sửa bài viết')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: PostMedia(
                    post: widget.post,
                    resolver: resolver,
                    onDoubleTapLike: () {},
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: EditPostScreen.captionKey,
                          controller: _caption,
                          maxLength: 2000,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Chú thích',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: EditPostScreen.tagsKey,
                          controller: _tags,
                          decoration: const InputDecoration(
                            labelText: 'Thẻ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_error case final message?) ...[
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: EditPostScreen.saveKey,
                          onPressed: _busy ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Lưu thay đổi'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: EditPostScreen.deleteKey,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                          ),
                          onPressed: _busy ? null : _confirmDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xóa bài viết'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
