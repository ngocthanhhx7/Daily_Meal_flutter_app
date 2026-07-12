import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/core/widgets/async_content.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_controller.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_card.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/recipe_nutrition_sheet.dart';
import 'package:daily_meal_flutter_app/features/comments/presentation/comments_sheet.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.controller != null &&
        widget.controller!.state.status == FeedStatus.idle) {
      widget.controller!.loadInitial().catchError((_) {});
    }
  }

  FeedController get _controller =>
      widget.controller ?? ref.read(feedControllerProvider);

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      _controller.loadMore().catchError((_) {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

    return AdaptiveScaffold(
      dailyMealStyle: true,
      destinations: const [
        AdaptiveDestination(icon: Icons.home_rounded, label: 'Trang chủ'),
        AdaptiveDestination(icon: Icons.search_rounded, label: 'Tìm kiếm'),
        AdaptiveDestination(icon: Icons.add_box_outlined, label: 'Đăng bài'),
        AdaptiveDestination(icon: Icons.chat_outlined, label: 'Tin nhắn'),
        AdaptiveDestination(icon: Icons.person_outline, label: 'Hồ sơ'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          context.goNamed(AppRoute.search.name);
        } else if (index == 2) {
          context.goNamed(AppRoute.createPost.name);
        } else if (index == 4) {
          context.goNamed(AppRoute.profile.name);
        } else if (index == 3) {
          context.goNamed(AppRoute.inbox.name);
        } else if (index != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng đang được hoàn thiện.')),
          );
        }
      },
      body: DailyMealBackground(
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Bảng tin',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.greenDark,
                              fontSize: 34,
                              height: 42 / 34,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Thông báo',
                        onPressed: () =>
                            context.pushNamed(AppRoute.notifications.name),
                        icon: Badge(
                          isLabelVisible: (notifications?.unreadCount ?? 0) > 0,
                          label: Text('${notifications?.unreadCount ?? 0}'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: AsyncContent<List<FeedPost>>(
                state: content,
                onRetry: () => controller.loadInitial().catchError((_) {}),
                dataBuilder: (context, posts) => RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: posts.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final post = posts[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 383),
                          child: FeedPostCard(
                            post: post,
                            resolver: resolver,
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
                            onComment: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => FractionallySizedBox(
                                heightFactor: 0.9,
                                child: CommentsSheet(postId: post.id),
                              ),
                            ),
                            onRecipe: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => FractionallySizedBox(
                                heightFactor: 0.92,
                                child: RecipeNutritionSheet(
                                  post: post,
                                  resolver: resolver,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
