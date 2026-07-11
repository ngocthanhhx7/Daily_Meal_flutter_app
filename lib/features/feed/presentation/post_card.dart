import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_media.dart';
import 'package:flutter/material.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    required this.post,
    required this.resolver,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onRecipe,
    this.interactionBusy = false,
    super.key,
  });

  final FeedPost post;
  final MediaUrlResolver resolver;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onRecipe;
  final bool interactionBusy;

  @override
  Widget build(BuildContext context) {
    final nutrition = post.nutritionSummary;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.green,
              child: Text(
                post.author.displayName.characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              post.author.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              post.author.isPremium
                  ? 'Premium creator • ${post.author.streakDays} ngày liên tiếp'
                  : 'Food journal • ${post.author.streakDays} ngày liên tiếp',
            ),
          ),
          PostMedia(
            post: post,
            resolver: resolver,
            onDoubleTapLike: interactionBusy ? () {} : onLike,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.sticker != null) ...[
                  Chip(label: Text(post.sticker!.name)),
                  const SizedBox(height: 8),
                ],
                Text(
                  post.caption.isEmpty
                      ? 'Một bữa ăn đáng nhớ trong ngày.'
                      : post.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post.tags.map((tag) => '#$tag').join('  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
                if (nutrition != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${nutrition.calories.round()} kcal • '
                    'P ${nutrition.protein.round()}g • '
                    'C ${nutrition.carbs.round()}g • '
                    'F ${nutrition.fat.round()}g',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _Action(
                  key: Key('like-${post.id}'),
                  icon: post.viewerState.liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.viewerState.liked ? AppColors.red : null,
                  count: post.stats.likes,
                  tooltip: 'Thích bài viết',
                  onPressed: interactionBusy ? null : onLike,
                ),
                _Action(
                  icon: Icons.chat_bubble_outline_rounded,
                  count: post.stats.comments,
                  tooltip: 'Bình luận',
                  onPressed: onComment,
                ),
                _Action(
                  key: Key('save-${post.id}'),
                  icon: post.viewerState.saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  count: post.stats.saves,
                  tooltip: 'Lưu bài viết',
                  onPressed: interactionBusy ? null : onSave,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Công thức',
                  onPressed: onRecipe,
                  icon: const Icon(Icons.restaurant_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
    this.color,
    super.key,
  });

  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$tooltip, $count',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(width: 5),
                Text('$count'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
