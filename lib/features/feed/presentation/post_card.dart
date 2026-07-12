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
    this.isOwner = false,
    this.onEdit,
    this.showActions = true,
    super.key,
  });

  final FeedPost post;
  final MediaUrlResolver resolver;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onRecipe;
  final bool interactionBusy;
  final bool isOwner;
  final VoidCallback? onEdit;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final nutrition = post.nutritionSummary;
    final caption = post.caption.isEmpty
        ? 'Một bữa ăn đáng nhớ trong ngày.'
        : post.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PostMedia(
              post: post,
              resolver: resolver,
              homeStyle: !showActions,
              onDoubleTapLike: interactionBusy ? () {} : onLike,
            ),
            Positioned(
              right: showActions ? 8 : 0,
              top: showActions ? 0 : 22,
              child: _OverlayPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 13),
                    const SizedBox(width: 3),
                    Text('${post.stats.comments}'),
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: AppColors.red,
                    ),
                    const SizedBox(width: 3),
                    Text('${post.stats.likes}'),
                  ],
                ),
              ),
            ),
            Positioned(
              left: showActions ? 4 : 0,
              bottom: 22,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: _OverlayPill(
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (post.sticker != null)
              Positioned(
                right: 2,
                bottom: 0,
                child: Image.asset(
                  'assets/stickers/openmoji-yum.png',
                  width: 56,
                  height: 56,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            if (!showActions &&
                (post.recipes.isNotEmpty || post.recipe != null))
              Positioned(
                left: 0,
                top: 24,
                child: FilledButton.icon(
                  onPressed: onRecipe,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.restaurant_menu, size: 17),
                  label: const Text('Công thức'),
                ),
              ),
            if (!showActions && nutrition != null)
              Positioned(
                right: 0,
                top: 62,
                child: _OverlayPill(
                  child: Text('${nutrition.calories.round()} kcal'),
                ),
              ),
            if (isOwner)
              Positioned(
                right: 0,
                top: 40,
                child: IconButton.filledTonal(
                  tooltip: 'Quản lý bài viết',
                  onPressed: onEdit,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.12),
                  offset: Offset(0, 4),
                  blurRadius: 9,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AuthorAvatar(
                    post: post,
                    resolver: resolver,
                    homeStyle: !showActions,
                  ),
                  SizedBox(width: showActions ? 6 : 12),
                  Text(
                    post.author.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: showActions ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!showActions && post.author.streakDays > 0) ...[
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/feed/streak.png',
                      width: 30,
                      height: 30,
                    ),
                    Text(
                      '${post.author.streakDays}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (post.tags.isNotEmpty || nutrition != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                if (post.tags.isNotEmpty)
                  Text(
                    post.tags.map((tag) => '#$tag').join('  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                if (nutrition != null)
                  Text(
                    '${nutrition.calories.round()} kcal',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        if (showActions)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Action(
                  key: Key('like-${post.id}'),
                  icon: post.viewerState.liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.viewerState.liked
                      ? AppColors.red
                      : AppColors.white,
                  count: post.stats.likes,
                  tooltip: 'Thích bài viết',
                  onPressed: interactionBusy ? null : onLike,
                ),
                _Action(
                  icon: Icons.chat_bubble_outline_rounded,
                  count: post.stats.comments,
                  tooltip: 'Bình luận',
                  color: AppColors.white,
                  onPressed: onComment,
                ),
                _Action(
                  key: Key('save-${post.id}'),
                  icon: post.viewerState.saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  count: post.stats.saves,
                  tooltip: 'Lưu bài viết',
                  color: post.viewerState.saved
                      ? AppColors.yellow
                      : AppColors.white,
                  onPressed: interactionBusy ? null : onSave,
                ),
                IconButton(
                  tooltip: 'Công thức',
                  onPressed: onRecipe,
                  color: AppColors.white,
                  icon: const Icon(Icons.restaurant_outlined, size: 18),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 7),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: DefaultTextStyle(
          style: const TextStyle(color: AppColors.black, fontSize: 10),
          child: child,
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.post,
    required this.resolver,
    required this.homeStyle,
  });
  final FeedPost post;
  final MediaUrlResolver resolver;
  final bool homeStyle;

  @override
  Widget build(BuildContext context) {
    final size = homeStyle ? 32.0 : 20.0;
    final uri = resolver.resolve(post.author.avatarUrl);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.surface,
      backgroundImage: uri == null ? null : NetworkImage(uri.toString()),
      child: uri == null
          ? Text(
              post.author.displayName.characters.first.toUpperCase(),
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: homeStyle ? 13 : 10,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
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
          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 21, color: color),
                if (tooltip == 'Lưu bài viết') ...[
                  const SizedBox(width: 4),
                  Text('$count', style: TextStyle(color: color)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
