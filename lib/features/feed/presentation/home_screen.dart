import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/widgets/async_content.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_controller.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_card.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_providers.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    this.controller,
    this.mediaResolver,
    this.currentUserId,
    this.notificationsController,
    super.key,
  });

  final FeedController? controller;
  final MediaUrlResolver? mediaResolver;
  final String? currentUserId;
  final NotificationsController? notificationsController;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null &&
        widget.controller!.state.status == FeedStatus.idle) {
      widget.controller!.loadInitial().catchError((_) {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller case final provided?) {
      return AnimatedBuilder(
        animation: provided,
        builder: (context, _) => _buildBody(provided),
      );
    }
    return _buildBody(ref.watch(feedControllerProvider));
  }

  Widget _buildBody(FeedController controller) {
    final MediaUrlResolver resolver;
    if (widget.mediaResolver case final provided?) {
      resolver = provided;
    } else {
      resolver = ref.watch(mediaUrlResolverProvider);
    }
    final state = controller.state;
    final notifications =
        widget.notificationsController ??
        (widget.controller == null
            ? ref.watch(notificationsControllerProvider)
            : null);
    final currentUserId =
        widget.currentUserId ??
        (widget.controller == null
            ? ref.watch(authControllerProvider).state.user?.id
            : null);
    final content = switch (state.status) {
      FeedStatus.idle ||
      FeedStatus.loading => const AsyncContentState<List<FeedPost>>.loading(),
      FeedStatus.empty => const AsyncContentState<List<FeedPost>>.empty(
        'Chưa có bài viết trong bảng tin.',
      ),
      FeedStatus.failure => AsyncContentState<List<FeedPost>>.error(
        state.errorMessage ?? 'Không thể tải bảng tin.',
      ),
      FeedStatus.ready => AsyncContentState<List<FeedPost>>.data(state.posts),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DailyMealBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Bảng tin',
                            maxLines: 1,
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 34,
                              height: 42 / 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Thông báo',
                          onPressed: () =>
                              context.pushNamed(AppRoute.notifications.name),
                          icon: Badge(
                            isLabelVisible:
                                (notifications?.unreadCount ?? 0) > 0,
                            label: Text(
                              (notifications?.unreadCount ?? 0) > 9
                                  ? '9+'
                                  : '${notifications?.unreadCount ?? 0}',
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/White/bell.svg',
                              width: 28,
                              height: 28,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hồ sơ',
                          onPressed: () =>
                              context.goNamed(AppRoute.profile.name),
                          icon: SvgPicture.asset(
                            'assets/icons/White/user_1.svg',
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AsyncContent<List<FeedPost>>(
                    state: content,
                    onRetry: () => controller.loadInitial().catchError((_) {}),
                    dataBuilder: (context, posts) => PageView.builder(
                      key: const Key('home-paged-feed'),
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: posts.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        if (index >= posts.length - 2) {
                          controller.loadMore().catchError((_) {});
                        }
                      },
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 383),
                              child: FeedPostCard(
                                post: post,
                                resolver: resolver,
                                showActions: false,
                                interactionBusy: controller.isInteractionBusy(
                                  post.id,
                                ),
                                isOwner: currentUserId == post.author.id,
                                onEdit: () => _editPost(controller, post),
                                onLike: () => controller
                                    .toggleLike(post.id)
                                    .catchError((_) {}),
                                onSave: () => controller
                                    .toggleSave(post.id)
                                    .catchError((_) {}),
                                onComment: () => _comments(post),
                                onRecipe: () => _recipe(post),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (state.posts.isNotEmpty)
                  _HomeActionBar(
                    post: state
                        .posts[_currentIndex.clamp(0, state.posts.length - 1)],
                    busy: controller.isInteractionBusy(
                      state
                          .posts[_currentIndex.clamp(0, state.posts.length - 1)]
                          .id,
                    ),
                    onCategory: _showCategory,
                    onComment: () => _comments(
                      state.posts[_currentIndex.clamp(
                        0,
                        state.posts.length - 1,
                      )],
                    ),
                    onLike: () => controller
                        .toggleLike(
                          state
                              .posts[_currentIndex.clamp(
                                0,
                                state.posts.length - 1,
                              )]
                              .id,
                        )
                        .catchError((_) {}),
                    onSave: () => controller
                        .toggleSave(
                          state
                              .posts[_currentIndex.clamp(
                                0,
                                state.posts.length - 1,
                              )]
                              .id,
                        )
                        .catchError((_) {}),
                    onCreate: () => context.pushNamed(AppRoute.createPost.name),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comments(FeedPost post) => context.pushNamed(
    AppRoute.comments.name,
    pathParameters: {'id': post.id},
    extra: post,
  );

  void _recipe(FeedPost post) => context.pushNamed(
    AppRoute.recipe.name,
    pathParameters: {'id': post.id},
    queryParameters: {'authorId': post.author.id},
    extra: post,
  );

  void _showCategory() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in const [
              (Icons.search_rounded, 'Tìm kiếm', AppRoute.search),
              (Icons.chat_bubble_outline, 'Tin nhắn', AppRoute.inbox),
              (Icons.person_outline, 'Hồ sơ', AppRoute.profile),
              (Icons.settings_outlined, 'Cài đặt', AppRoute.settings),
            ])
              InkWell(
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.goNamed(item.$3.name);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1),
                      const SizedBox(height: 6),
                      Text(item.$2),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _editPost(FeedController controller, FeedPost post) async {
    final result = await context.pushNamed<Object?>(
      AppRoute.editPost.name,
      extra: post,
    );
    if (!mounted) return;
    if (result is FeedPost) {
      controller.applyPost(result);
    } else if (result is String) {
      controller.removePost(result);
    }
  }
}

class _HomeActionBar extends StatelessWidget {
  const _HomeActionBar({
    required this.post,
    required this.busy,
    required this.onCategory,
    required this.onComment,
    required this.onLike,
    required this.onSave,
    required this.onCreate,
  });
  final FeedPost post;
  final bool busy;
  final VoidCallback onCategory, onComment, onLike, onSave, onCreate;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(34, 8, 34, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _assetButton(
            'assets/icons/White/Category.svg',
            'Danh mục',
            onCategory,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onComment,
                    icon: SvgPicture.asset(
                      'assets/icons/Dark/Message_1.svg',
                      width: 26,
                      height: 26,
                    ),
                    tooltip: 'Bình luận',
                  ),
                  IconButton(
                    key: Key('like-${post.id}'),
                    onPressed: busy ? null : onLike,
                    icon: SvgPicture.asset(
                      'assets/icons/Dark/Heart.svg',
                      width: 28,
                      height: 28,
                      colorFilter: post.viewerState.liked
                          ? const ColorFilter.mode(
                              AppColors.red,
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                    tooltip: 'Thích',
                  ),
                  IconButton(
                    key: Key('save-${post.id}'),
                    onPressed: busy ? null : onSave,
                    icon: SvgPicture.asset(
                      'assets/icons/Dark/bookmark.svg',
                      width: 27,
                      height: 27,
                      colorFilter: post.viewerState.saved
                          ? const ColorFilter.mode(
                              AppColors.yellow,
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                    tooltip: 'Lưu',
                  ),
                ],
              ),
            ),
          ),
          _assetButton('assets/icons/White/Camera.svg', 'Đăng bài', onCreate),
        ],
      ),
    ),
  );

  static Widget _assetButton(
    String asset,
    String tooltip,
    VoidCallback onTap,
  ) => SizedBox.square(
    dimension: 52,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: SvgPicture.asset(asset, width: 30, height: 30),
    ),
  );
}
