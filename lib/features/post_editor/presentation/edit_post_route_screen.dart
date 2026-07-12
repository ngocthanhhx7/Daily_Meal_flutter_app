import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/data/post_lookup_repository.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/edit_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditPostRouteScreen extends ConsumerStatefulWidget {
  const EditPostRouteScreen({
    required this.postId,
    required this.authorId,
    this.post,
    this.lookupRepository,
    this.managementRepository,
    this.mediaResolver,
    super.key,
  });
  final String postId, authorId;
  final FeedPost? post;
  final PostLookupRepositoryContract? lookupRepository;
  final PostManagementRepositoryContract? managementRepository;
  final MediaUrlResolver? mediaResolver;
  @override
  ConsumerState<EditPostRouteScreen> createState() =>
      _EditPostRouteScreenState();
}

class _EditPostRouteScreenState extends ConsumerState<EditPostRouteScreen> {
  FeedPost? _post;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post == null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final PostLookupRepositoryContract repository =
          widget.lookupRepository ?? ref.read(postLookupRepositoryProvider);
      final post = await repository.findByAuthor(
        postId: widget.postId,
        authorId: widget.authorId,
      );
      if (mounted) setState(() => _post = post);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải bài viết để chỉnh sửa.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post == null) {
      return Scaffold(
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(_error!),
                ),
        ),
      );
    }
    return EditPostScreen(
      post: post,
      repository: widget.managementRepository,
      mediaResolver: widget.mediaResolver,
      onUpdated: (updated) => context.pop(updated),
      onDeleted: (id) => context.pop(id),
    );
  }
}
