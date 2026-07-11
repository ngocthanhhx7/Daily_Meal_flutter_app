import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/core/widgets/async_content.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_controller.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({this.controller, this.mediaResolver, super.key});

  final FeedController? controller;
  final MediaUrlResolver? mediaResolver;

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
      destinations: const [
        AdaptiveDestination(icon: Icons.home_rounded, label: 'Trang chủ'),
        AdaptiveDestination(icon: Icons.search_rounded, label: 'Tìm kiếm'),
        AdaptiveDestination(icon: Icons.add_box_outlined, label: 'Đăng bài'),
        AdaptiveDestination(icon: Icons.chat_outlined, label: 'Tin nhắn'),
        AdaptiveDestination(icon: Icons.person_outline, label: 'Hồ sơ'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng đang được hoàn thiện.')),
          );
        }
      },
      body: ColoredBox(
        color: AppColors.canvas,
        child: Column(
          children: [
            Material(
              color: AppColors.surface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Daily Meal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Thông báo',
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined),
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
                    padding: const EdgeInsets.all(16),
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
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: FeedPostCard(
                            post: post,
                            resolver: resolver,
                            interactionBusy: controller.isInteractionBusy(
                              post.id,
                            ),
                            onLike: () => controller
                                .toggleLike(post.id)
                                .catchError((_) {}),
                            onSave: () => controller
                                .toggleSave(post.id)
                                .catchError((_) {}),
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
}
