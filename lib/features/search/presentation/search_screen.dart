import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_compact_post_preview.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/search/application/search_controller.dart'
    as app_search;
import 'package:daily_meal_flutter_app/features/search/application/search_providers.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.controller, this.mediaResolver, super.key});
  final app_search.SearchController? controller;
  final MediaUrlResolver? mediaResolver;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller != null &&
        widget.controller!.state.status == app_search.SearchStatus.idle) {
      widget.controller!.searchNow().catchError((_) {});
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
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchBar(
                  controller: query,
                  hintText: 'Tìm món ăn, bài viết hoặc người dùng',
                  leading: const Icon(Icons.search_rounded),
                  onChanged: controller.updateQuery,
                  onSubmitted: (_) => controller.searchNow().catchError((_) {}),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Dưới 500 kcal'),
                        selected: state.filters.maxCalories == 500,
                        onSelected: (value) => controller.updateFilters(
                          state.filters.copyWith(
                            maxCalories: value ? 500 : null,
                            clearMaxCalories: !value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Đã lưu'),
                        selected: state.filters.saved,
                        onSelected: (value) => controller.updateFilters(
                          state.filters.copyWith(saved: value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sticker Premium'),
                        selected: state.filters.premiumSticker,
                        onSelected: (value) => controller.updateFilters(
                          state.filters.copyWith(premiumSticker: value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Cá nhân hóa'),
                        selected: state.filters.personalized,
                        onSelected: (value) => controller.updateFilters(
                          state.filters.copyWith(personalized: value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<app_search.SearchMode>(
                  segments: [
                    ButtonSegment(
                      value: app_search.SearchMode.posts,
                      icon: const Icon(Icons.grid_view_rounded),
                      label: Text('Bài viết (${state.posts.length})'),
                    ),
                    ButtonSegment(
                      value: app_search.SearchMode.people,
                      icon: const Icon(Icons.people_outline_rounded),
                      label: Text('Mọi người (${state.users.length})'),
                    ),
                  ],
                  selected: {state.mode},
                  onSelectionChanged: (value) =>
                      controller.updateMode(value.first),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: SizedBox(
          width: constraints.maxWidth > 380 ? 380 : constraints.maxWidth,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 160 / 208,
            ),
            itemCount: state.posts.length,
            itemBuilder: (context, index) {
              final post = state.posts[index];
              return DailyCompactPostPreview(
                post: post,
                resolver: resolver,
                onOpen: () => _recipe(context, post),
                onLike: controller.isPostBusy(post.id)
                    ? null
                    : () => controller.toggleLike(post.id).catchError((_) {}),
                onSave: controller.isPostBusy(post.id)
                    ? null
                    : () => controller.toggleSave(post.id).catchError((_) {}),
              );
            },
          ),
        ),
      ),
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
    return Card(
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: avatar == null
              ? null
              : NetworkImage(avatar.toString()),
          child: avatar == null
              ? Text(user.displayName.characters.first.toUpperCase())
              : null,
        ),
        title: Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${user.counts.posts} bài viết • ${user.counts.followers} người theo dõi',
        ),
        trailing: FilledButton.tonal(
          onPressed: busy ? null : onFollow,
          child: Text(
            user.relationship.isFollowing ? 'Đang theo dõi' : 'Theo dõi',
          ),
        ),
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
