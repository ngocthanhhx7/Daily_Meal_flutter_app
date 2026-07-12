import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/comments/presentation/comments_sheet.dart';
import 'package:daily_meal_flutter_app/features/comments/application/comments_controller.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class CommentsScreen extends ConsumerWidget {
  const CommentsScreen({
    required this.postId,
    this.post,
    this.controller,
    this.mediaResolver,
    super.key,
  });
  final String postId;
  final FeedPost? post;
  final CommentsController? controller;
  final MediaUrlResolver? mediaResolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstImage = post == null || post!.images.isEmpty
        ? null
        : post!.images.first.url;
    final MediaUrlResolver resolver =
        mediaResolver ?? ref.watch(mediaUrlResolverProvider);
    final uri = resolver.resolve(firstImage);
    final fallback = Image.asset(
      'assets/figma-snapshots/image3.png',
      width: double.infinity,
      fit: BoxFit.cover,
    );
    final hero = uri == null
        ? fallback
        : Image.network(
            uri.toString(),
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
    return Scaffold(
      body: DailyMealBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          onPressed: context.pop,
                          icon: SvgPicture.asset(
                            'assets/icons/White/Arrow_Left_circle.svg',
                            width: 20,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Bình luận',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.more_horiz, size: 30),
                        const SizedBox(width: 8),
                        const Icon(Icons.person, size: 30),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 128,
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(28),
                          ),
                        ),
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Color(0x17FFFFFF),
                              Colors.transparent,
                            ],
                            stops: [0, .18, .55, 1],
                          ).createShader(bounds),
                          child: hero,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, 20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 21,
                                  backgroundColor: AppColors.green,
                                  child: Text(
                                    post?.author.displayName.characters.first
                                            .toUpperCase() ??
                                        'D',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text('${post?.stats.comments ?? 0}'),
                                const SizedBox(width: 5),
                                const Icon(Icons.chat_bubble_outline, size: 17),
                                const SizedBox(width: 18),
                                Text('${post?.stats.likes ?? 0}'),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.favorite,
                                  size: 17,
                                  color: AppColors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: CommentsSheet(
                      postId: controller == null ? postId : null,
                      controller: controller,
                      mediaResolver: resolver,
                      currentUserId: controller == null
                          ? ref.watch(authControllerProvider).state.user?.id
                          : null,
                      embedded: true,
                    ),
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
