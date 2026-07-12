import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_card.dart';
import 'package:daily_meal_flutter_app/features/search/application/search_controller.dart'
    as app_search;
import 'package:daily_meal_flutter_app/features/search/application/search_providers.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    this.controller,
    this.mediaResolver,
    this.initialQuery = '',
    this.initialMode,
    super.key,
  });
  final app_search.SearchController? controller;
  final MediaUrlResolver? mediaResolver;
  final String initialQuery;
  final app_search.SearchMode? initialMode;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.text = widget.initialQuery;
    if (widget.controller != null) {
      widget.controller!
          .initialize(query: widget.initialQuery, mode: widget.initialMode)
          .catchError((_) {});
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(searchControllerProvider)
            .initialize(query: widget.initialQuery, mode: widget.initialMode)
            .catchError((_) {});
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller case final controller?) {
      return AnimatedBuilder(
        animation: controller,
        builder: (_, _) => _body(controller),
      );
    }
    return _body(ref.watch(searchControllerProvider));
  }

  Widget _body(app_search.SearchController controller) => AdaptiveScaffold(
    dailyMealStyle: true,
    destinations: const [
      AdaptiveDestination(icon: Icons.home_rounded, label: 'Trang chủ'),
      AdaptiveDestination(icon: Icons.search_rounded, label: 'Tìm kiếm'),
      AdaptiveDestination(icon: Icons.add_box_outlined, label: 'Đăng bài'),
      AdaptiveDestination(icon: Icons.chat_outlined, label: 'Tin nhắn'),
      AdaptiveDestination(icon: Icons.person_outline, label: 'Hồ sơ'),
    ],
    selectedIndex: 1,
    onDestinationSelected: (index) {
      if (index == 0) context.goNamed(AppRoute.home.name);
      if (index == 2) context.goNamed(AppRoute.createPost.name);
      if (index == 4) context.goNamed(AppRoute.profile.name);
      if (index == 3) context.goNamed(AppRoute.inbox.name);
    },
    body: DailyMealBackground(
      child: SafeArea(
        child: Column(
          children: [
            _Header(controller: controller, query: _query),
            Expanded(
              child: _Results(
                controller: controller,
                resolver:
                    widget.mediaResolver ?? ref.watch(mediaUrlResolverProvider),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.query});
  final app_search.SearchController controller;
  final TextEditingController query;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.chevron_left, size: 26),
                    ),
                    const Expanded(
                      child: Text(
                        'Tìm kiếm',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.goNamed(AppRoute.home.name),
                      icon: const Icon(Icons.home_outlined, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5E8),
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: Color(0xFFE8F0DE),
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          color: AppColors.greenDark,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khám phá bữa ăn phù hợp',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tìm món ăn, nguyên liệu, người dùng hoặc thẻ yêu thích.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: query,
                        textInputAction: TextInputAction.search,
                        onChanged: controller.updateQuery,
                        onSubmitted: (_) =>
                            controller.searchNow().catchError((_) {}),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () =>
                            controller.searchNow().catchError((_) {}),
                        child: Icon(
                          state.status == app_search.SearchStatus.loading
                              ? Icons.refresh_rounded
                              : Icons.search_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SearchFilter(
                      label: 'Dưới 500 calo',
                      selected: state.filters.maxCalories == 500,
                      onTap: () => controller.updateFilters(
                        state.filters.copyWith(
                          maxCalories: state.filters.maxCalories == 500
                              ? null
                              : 500,
                          clearMaxCalories: state.filters.maxCalories == 500,
                        ),
                      ),
                    ),
                    _SearchFilter(
                      label: 'Đã lưu',
                      selected: state.filters.saved,
                      onTap: () => controller.updateFilters(
                        state.filters.copyWith(saved: !state.filters.saved),
                      ),
                    ),
                    _SearchFilter(
                      label: 'Sticker VIP',
                      selected: state.filters.premiumSticker,
                      onTap: () => controller.updateFilters(
                        state.filters.copyWith(
                          premiumSticker: !state.filters.premiumSticker,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEAE0),
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      _SearchModeButton(
                        label: 'Bài viết',
                        selected: state.mode == app_search.SearchMode.posts,
                        onTap: () =>
                            controller.updateMode(app_search.SearchMode.posts),
                      ),
                      const SizedBox(width: 6),
                      _SearchModeButton(
                        label: 'Người dùng',
                        selected: state.mode == app_search.SearchMode.people,
                        onTap: () =>
                            controller.updateMode(app_search.SearchMode.people),
                      ),
                    ],
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

class _SearchFilter extends StatelessWidget {
  const _SearchFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.black : AppColors.surface,
        border: Border.all(color: selected ? AppColors.black : AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.white : AppColors.ink,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _SearchModeButton extends StatelessWidget {
  const _SearchModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 38),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _Results extends StatelessWidget {
  const _Results({required this.controller, required this.resolver});
  final app_search.SearchController controller;
  final MediaUrlResolver resolver;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    if (state.status == app_search.SearchStatus.loading &&
        state.posts.isEmpty &&
        state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == app_search.SearchStatus.failure &&
        state.posts.isEmpty &&
        state.users.isEmpty) {
      return _Message(
        message: 'Không thể tải kết quả tìm kiếm.',
        retry: () => controller.searchNow().catchError((_) {}),
      );
    }
    if (state.mode == app_search.SearchMode.people) {
      if (state.users.isEmpty) {
        return const _Message(message: 'Không tìm thấy người dùng phù hợp.');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _UserCard(
              user: state.users[index],
              resolver: resolver,
              busy: controller.isFollowBusy(state.users[index].id),
              onFollow: () => controller
                  .toggleFollow(state.users[index].id)
                  .catchError((_) {}),
              onOpen: () => context.pushNamed(
                AppRoute.publicProfile.name,
                pathParameters: {'id': state.users[index].id},
              ),
            ),
          ),
        ),
      );
    }
    if (state.posts.isEmpty) {
      return const _Message(message: 'Không tìm thấy bài viết phù hợp.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: state.posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 28),
      itemBuilder: (context, index) {
        final post = state.posts[index];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: FeedPostCard(
              post: post,
              resolver: resolver,
              interactionBusy: controller.isPostBusy(post.id),
              onLike: () => controller.toggleLike(post.id).catchError((_) {}),
              onSave: () => controller.toggleSave(post.id).catchError((_) {}),
              onComment: () => context.pushNamed(
                AppRoute.comments.name,
                pathParameters: {'id': post.id},
                extra: post,
              ),
              onRecipe: () => _recipe(context, post),
              onAuthor: () => context.pushNamed(
                AppRoute.publicProfile.name,
                pathParameters: {'id': post.author.id},
              ),
            ),
          ),
        );
      },
    );
  }

  void _recipe(BuildContext context, FeedPost post) => context.pushNamed(
    AppRoute.recipe.name,
    pathParameters: {'id': post.id},
    queryParameters: {'authorId': post.author.id},
    extra: post,
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.resolver,
    required this.busy,
    required this.onFollow,
    required this.onOpen,
  });
  final PublicUser user;
  final MediaUrlResolver resolver;
  final bool busy;
  final VoidCallback onFollow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final avatar = resolver.resolve(user.avatarUrl);
    final following = user.relationship.isFollowing;
    final label = user.relationship.isFriend
        ? 'Bạn bè'
        : following
        ? 'Đang theo dõi'
        : user.relationship.followsMe
        ? 'Theo dõi lại'
        : 'Theo dõi';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.green,
                    backgroundImage: avatar == null
                        ? null
                        : NetworkImage(avatar.toString()),
                    child: avatar == null
                        ? Text(
                            user.displayName.characters.first.toUpperCase(),
                            style: const TextStyle(color: AppColors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          (user.bio?.trim().isNotEmpty ?? false)
                              ? user.bio!
                              : '${user.counts.followers} người theo dõi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: following ? AppColors.surface : AppColors.yellow,
              foregroundColor: AppColors.black,
              side: BorderSide(
                color: following ? AppColors.line : AppColors.yellow,
              ),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: busy ? null : onFollow,
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off_rounded, size: 48),
        const SizedBox(height: 12),
        Text(message),
        if (retry != null)
          OutlinedButton(onPressed: retry, child: const Text('Thử lại')),
      ],
    ),
  );
}
