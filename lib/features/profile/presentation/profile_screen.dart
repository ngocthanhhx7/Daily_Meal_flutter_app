import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_providers.dart';
import 'package:daily_meal_flutter_app/features/post_editor/services/media_picker_service.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/messaging_providers.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    this.userId,
    this.controller,
    this.mediaResolver,
    this.mediaPicker,
    this.showSaved = false,
    super.key,
  });
  final String? userId;
  final ProfileController? controller;
  final MediaUrlResolver? mediaResolver;
  final MediaPickerService? mediaPicker;
  final bool showSaved;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProfileController? _owned;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null || _owned != null) return;
    final ownId = ref.read(authControllerProvider).state.user?.id;
    final target = widget.userId ?? ownId;
    if (target == null) return;
    _owned = ProfileController(
      ref.read(profileRepositoryProvider),
      userId: target,
      isOwner: widget.userId == null || widget.userId == ownId,
    );
    _owned!
        .load()
        .then((_) {
          if (widget.showSaved && mounted) _owned!.selectTab(ProfileTab.saved);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? _owned;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => _screen(controller),
    );
  }

  Widget _screen(ProfileController controller) => AdaptiveScaffold(
    dailyMealStyle: true,
    destinations: const [
      AdaptiveDestination(icon: Icons.home_rounded, label: 'Trang chủ'),
      AdaptiveDestination(icon: Icons.search_rounded, label: 'Tìm kiếm'),
      AdaptiveDestination(icon: Icons.add_box_outlined, label: 'Đăng bài'),
      AdaptiveDestination(icon: Icons.chat_outlined, label: 'Tin nhắn'),
      AdaptiveDestination(icon: Icons.person_outline, label: 'Hồ sơ'),
    ],
    selectedIndex: 4,
    onDestinationSelected: (index) {
      if (index == 0) context.goNamed(AppRoute.home.name);
      if (index == 1) context.goNamed(AppRoute.search.name);
      if (index == 2) context.goNamed(AppRoute.createPost.name);
      if (index == 3) context.goNamed(AppRoute.inbox.name);
      if (index == 4 && !controller.isOwner) {
        context.goNamed(AppRoute.profile.name);
      }
    },
    body: DailyMealBackground(
      child: _content(
        controller,
        widget.mediaResolver ?? ref.watch(mediaUrlResolverProvider),
      ),
    ),
  );

  Widget _content(ProfileController controller, MediaUrlResolver resolver) {
    final state = controller.state;
    if (state.status == ProfileStatus.idle ||
        state.status == ProfileStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ProfileStatus.failure || state.user == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () => controller.load().catchError((_) {}),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tải lại hồ sơ'),
        ),
      );
    }
    final user = state.user!;
    final posts = state.tab == ProfileTab.posts
        ? state.posts
        : state.savedPosts;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            user: user,
            controller: controller,
            resolver: resolver,
            mediaPicker: widget.mediaPicker ?? PluginMediaPickerService(),
            onMessage: controller.isOwner
                ? null
                : () => _startConversation(user),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<ProfileTab>(
                segments: [
                  const ButtonSegment(
                    value: ProfileTab.posts,
                    icon: Icon(Icons.grid_view_rounded),
                    label: Text('Bài viết'),
                  ),
                  if (controller.isOwner)
                    const ButtonSegment(
                      value: ProfileTab.saved,
                      icon: Icon(Icons.bookmark_outline),
                      label: Text('Đã lưu'),
                    ),
                ],
                selected: {state.tab},
                onSelectionChanged: (value) =>
                    controller.selectTab(value.first),
              ),
            ),
          ),
        ),
        _PostGrid(posts: posts, resolver: resolver),
      ],
    );
  }

  Future<void> _startConversation(PublicUser user) async {
    try {
      final conversation = await ref
          .read(messagingRepositoryProvider)
          .createConversation(user.id);
      if (!mounted) return;
      context.pushNamed(
        AppRoute.chat.name,
        pathParameters: {'id': conversation.id},
        extra: conversation.otherUser,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể bắt đầu cuộc trò chuyện.')),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.controller,
    required this.resolver,
    required this.mediaPicker,
    this.onMessage,
  });
  final PublicUser user;
  final ProfileController controller;
  final MediaUrlResolver resolver;
  final MediaPickerService mediaPicker;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final cover = resolver.resolve(user.coverUrl);
    final avatar = resolver.resolve(user.avatarUrl);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: cover == null
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.greenDark, AppColors.green],
                          ),
                        ),
                      )
                    : Image.network(cover.toString(), fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                child: Column(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -38),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.surface,
                        child: CircleAvatar(
                          radius: 41,
                          backgroundImage: avatar == null
                              ? null
                              : NetworkImage(avatar.toString()),
                          child: avatar == null
                              ? Text(user.displayName.characters.first)
                              : null,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -25),
                      child: Column(
                        children: [
                          Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (user.bio?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                user.bio!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _Count(user.counts.posts, 'Bài viết'),
                              ),
                              Expanded(
                                child: _Count(
                                  user.counts.followers,
                                  'Người theo dõi',
                                  () => _follows(context, true),
                                ),
                              ),
                              Expanded(
                                child: _Count(
                                  user.counts.following,
                                  'Đang theo dõi',
                                  () => _follows(context, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (controller.isOwner)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: controller.state.profileBusy
                                      ? null
                                      : () =>
                                            _pickImage(ProfileImageKind.avatar),
                                  icon: const Icon(
                                    Icons.account_circle_outlined,
                                  ),
                                  label: const Text('Đổi avatar'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: controller.state.profileBusy
                                      ? null
                                      : () =>
                                            _pickImage(ProfileImageKind.cover),
                                  icon: const Icon(Icons.panorama_outlined),
                                  label: const Text('Đổi ảnh bìa'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: controller.state.profileBusy
                                      ? null
                                      : () => _edit(context),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Chỉnh sửa hồ sơ'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      context.pushNamed(AppRoute.blocked.name),
                                  icon: const Icon(Icons.block_outlined),
                                  label: const Text('Đã chặn'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      context.pushNamed(AppRoute.premium.name),
                                  icon: const Icon(
                                    Icons.workspace_premium_outlined,
                                  ),
                                  label: const Text('Daily Premium'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      context.pushNamed(AppRoute.settings.name),
                                  icon: const Icon(Icons.settings_outlined),
                                  label: const Text('Cài đặt'),
                                ),
                              ],
                            )
                          else
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: onMessage,
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Nhắn tin'),
                                ),
                                FilledButton.icon(
                                  onPressed: controller.state.followBusy
                                      ? null
                                      : () => controller
                                            .toggleFollow()
                                            .catchError((_) {}),
                                  icon: Icon(
                                    user.relationship.isFollowing
                                        ? Icons.check
                                        : Icons.person_add_alt_1,
                                  ),
                                  label: Text(
                                    user.relationship.isFollowing
                                        ? 'Đang theo dõi'
                                        : 'Theo dõi',
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'An toàn tài khoản',
                                  enabled: !controller.state.safetyBusy,
                                  onSelected: (type) =>
                                      _confirmSafety(context, type),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'restrict',
                                      child: Text(
                                        user.viewerInteraction.restricted
                                            ? 'Bỏ hạn chế'
                                            : 'Hạn chế',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Text(
                                        user.viewerInteraction.blocked
                                            ? 'Bỏ chặn'
                                            : 'Chặn',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'report',
                                      child: Text(
                                        user.viewerInteraction.reported
                                            ? 'Gỡ báo cáo'
                                            : 'Báo cáo',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _follows(BuildContext context, bool followers) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => _FollowsSheet(
          title: followers ? 'Người theo dõi' : 'Đang theo dõi',
          future: controller.loadFollows(followers: followers),
          resolver: resolver,
        ),
      );

  Future<void> _edit(BuildContext context) async {
    var name = user.displayName;
    var bio = user.bio ?? '';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                maxLength: 80,
                onChanged: (value) => name = value,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
              ),
              TextFormField(
                initialValue: bio,
                maxLength: 240,
                maxLines: 3,
                onChanged: (value) => bio = value,
                decoration: const InputDecoration(labelText: 'Giới thiệu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final normalizedName = name.trim();
              if (normalizedName.isEmpty) return;
              Navigator.pop(context, {
                'displayName': normalizedName,
                'bio': bio.trim(),
              });
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await controller.updateProfile(result).catchError((_) {});
    }
  }

  Future<void> _pickImage(ProfileImageKind kind) async {
    final picked = await mediaPicker.pickImages(limit: 1);
    if (picked.isEmpty) return;
    await controller.updateProfileImage(picked.first, kind).catchError((_) {});
  }

  Future<void> _confirmSafety(BuildContext context, String type) async {
    final current = user.viewerInteraction;
    final active = switch (type) {
      'restrict' => !current.restricted,
      'block' => !current.blocked,
      _ => !current.reported,
    };
    final label = switch (type) {
      'restrict' => active ? 'hạn chế' : 'bỏ hạn chế',
      'block' => active ? 'chặn' : 'bỏ chặn',
      _ => active ? 'báo cáo' : 'gỡ báo cáo',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $label'),
        content: Text('Bạn có chắc muốn $label ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.setSafety(type, active: active).catchError((_) {});
    }
  }
}

class _Count extends StatelessWidget {
  const _Count(this.value, this.label, [this.onTap]);
  final int value;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _PostGrid extends StatelessWidget {
  const _PostGrid({required this.posts, required this.resolver});
  final List<FeedPost> posts;
  final MediaUrlResolver resolver;
  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Chưa có bài viết.')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: posts.length,
        itemBuilder: (_, index) {
          final post = posts[index];
          final image = post.images.isEmpty
              ? null
              : resolver.resolve(post.images.first.url);
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image.network(image.toString(), fit: BoxFit.cover),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          post.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FollowsSheet extends StatelessWidget {
  const _FollowsSheet({
    required this.title,
    required this.future,
    required this.resolver,
  });
  final String title;
  final Future<List<PublicUser>> future;
  final MediaUrlResolver resolver;
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .75,
    child: Column(
      children: [
        ListTile(
          title: Text(title),
          trailing: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PublicUser>>(
            future: future,
            builder: (_, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Không thể tải danh sách.'));
              }
              final users = snapshot.data ?? const [];
              if (users.isEmpty) {
                return const Center(child: Text('Danh sách đang trống.'));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(users[index].displayName),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed(
                      AppRoute.publicProfile.name,
                      pathParameters: {'id': users[index].id},
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
