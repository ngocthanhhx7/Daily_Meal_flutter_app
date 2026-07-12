import 'dart:math' as math;

import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/material.dart';

class DailyCompactPostPreview extends StatelessWidget {
  const DailyCompactPostPreview({
    required this.post,
    required this.resolver,
    this.onOpen,
    this.onLike,
    this.onSave,
    this.showAuthor = true,
    super.key,
  });

  final FeedPost post;
  final MediaUrlResolver resolver;
  final VoidCallback? onOpen;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final images = post.images
        .map((image) => resolver.resolve(image.url))
        .whereType<Uri>()
        .take(2)
        .toList(growable: false);
    return Semantics(
      button: onOpen != null,
      label: 'Bài viết của ${post.author.displayName}: ${post.caption}',
      child: GestureDetector(
        onTap: onOpen,
        child: SizedBox(
          height: 208,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(160.0, constraints.maxWidth);
              return Center(
                child: SizedBox(
                  width: width,
                  height: 208,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (images.isEmpty)
                        _PreviewImage(width: width, uri: null, angle: 0)
                      else
                        for (var index = 0; index < images.length; index++)
                          Positioned(
                            left: index == 0 ? 0 : width * .08,
                            top: index == 0 ? 8 : 0,
                            child: _PreviewImage(
                              width: width * (index == 0 ? .94 : .92),
                              uri: images[index],
                              angle: index == 0 ? -.035 : .035,
                            ),
                          ),
                      Positioned(
                        left: 4,
                        top: 10,
                        child: _Pill(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: width * .62),
                            child: Text(
                              post.caption.isEmpty
                                  ? 'Nó ngon...'
                                  : post.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 3,
                        top: 10,
                        child: _Pill(
                          child: Text(
                            '${post.stats.comments} ◌  ${post.stats.likes} ♥',
                          ),
                        ),
                      ),
                      if (showAuthor)
                        Positioned(
                          left: 8,
                          bottom: 4,
                          child: _Pill(
                            color: AppColors.green.withValues(alpha: .94),
                            child: Text(
                              post.author.displayName,
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                        ),
                      if (onLike != null)
                        Positioned(
                          right: 32,
                          bottom: -4,
                          child: IconButton(
                            key: Key('compact-like-${post.id}'),
                            tooltip: 'Thích bài viết',
                            onPressed: onLike,
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              post.viewerState.liked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: post.viewerState.liked
                                  ? AppColors.red
                                  : AppColors.black,
                            ),
                          ),
                        ),
                      if (onSave != null)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: IconButton(
                            key: Key('compact-save-${post.id}'),
                            tooltip: 'Lưu bài viết',
                            onPressed: onSave,
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              post.viewerState.saved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.width,
    required this.uri,
    required this.angle,
  });

  final double width;
  final Uri? uri;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, .2),
            offset: Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: width,
          height: 188,
          child: uri == null
              ? const ColoredBox(
                  color: AppColors.canvasStrong,
                  child: Icon(Icons.restaurant_menu, color: AppColors.green),
                )
              : Image.network(
                  uri.toString(),
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppColors.canvasStrong,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color ?? AppColors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 9, color: AppColors.black),
        child: child,
      ),
    ),
  );
}
