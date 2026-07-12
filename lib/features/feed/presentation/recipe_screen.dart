import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/data/post_lookup_repository.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/recipe_nutrition_sheet.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({
    required this.postId,
    required this.authorId,
    this.post,
    this.repository,
    this.mediaResolver,
    super.key,
  });
  final String postId;
  final String authorId;
  final FeedPost? post;
  final PostLookupRepositoryContract? repository;
  final MediaUrlResolver? mediaResolver;
  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  FeedPost? _post;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post == null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final PostLookupRepositoryContract repository =
          widget.repository ?? ref.read(postLookupRepositoryProvider);
      final FeedPost post;
      if (widget.authorId.isNotEmpty) {
        post = await repository.findByAuthor(
          postId: widget.postId,
          authorId: widget.authorId,
        );
      } else {
        final feed = ref.read(feedControllerProvider);
        final index = await feed.findPost(widget.postId);
        if (index < 0) throw StateError('Post is unavailable');
        post = feed.state.posts[index];
      }
      if (mounted) setState(() => _post = post);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải công thức của bài viết.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _post == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_post == null) {
      return Scaffold(
        body: Center(
          child: OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(_error ?? 'Tải lại'),
          ),
        ),
      );
    }
    final MediaUrlResolver resolver =
        widget.mediaResolver ?? ref.watch(mediaUrlResolverProvider);
    return Scaffold(
      body: RecipeNutritionSheet(post: _post!, resolver: resolver),
    );
  }
}
