import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_compact_post_preview.dart';
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
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    this.userId,
    this.controller,
    this.mediaResolver,
    this.mediaPicker,
    this.showSaved = false,
    this.shareProfile,
    super.key,
  });
  final String? userId;
  final ProfileController? controller;
  final MediaUrlResolver? mediaResolver;
  final MediaPickerService? mediaPicker;
  final bool showSaved;
  final Future<void> Function(PublicUser user)? shareProfile;
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
            useInlineEditor: widget.controller != null,
            onMessage: controller.isOwner
                ? null
                : () => _startConversation(user),
            onShare: controller.isOwner ? () => _shareProfile(user) : null,
            onOwnerMenu: controller.isOwner
                ? () => _openOwnerMenu(context)
                : null,
          ),
        ),
        SliverToBoxAdapter(
          child: _ProfileTabs(
            selected: state.tab,
            showSaved: controller.isOwner,
            onSelected: controller.selectTab,
          ),
        ),
        _PostGrid(
          posts: posts,
          resolver: resolver,
          onOpen: (post) {
            if (controller.isOwner && state.tab == ProfileTab.posts) {
              context.pushNamed(
                AppRoute.editPost.name,
                pathParameters: {'id': post.id},
                queryParameters: {'authorId': post.author.id},
                extra: post,
              );
              return;
            }
            context.goNamed(
              AppRoute.home.name,
              queryParameters: {'postId': post.id},
            );
          },
        ),
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

  Future<void> _shareProfile(PublicUser user) async {
    if (widget.shareProfile case final share?) {
      await share(user);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${user.displayName} trên Daily Meal '
            'https://dailymeal.site/users/${user.id}',
      ),
    );
  }

  Future<void> _openOwnerMenu(BuildContext context) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OwnerMenuItem('inbox', Icons.chat_bubble_outline, 'Tin nhắn'),
            _OwnerMenuItem('password', Icons.key_outlined, 'Đổi mật khẩu'),
            _OwnerMenuItem('settings', Icons.settings_outlined, 'Cài đặt'),
            _OwnerMenuItem('logout', Icons.logout, 'Đăng xuất', danger: true),
          ],
        ),
      ),
    );
    if (!context.mounted || selection == null) return;
    switch (selection) {
      case 'inbox':
        context.pushNamed(AppRoute.inbox.name);
      case 'password':
        context.pushNamed(AppRoute.changePassword.name);
      case 'settings':
        context.pushNamed(AppRoute.settings.name);
      case 'logout':
        await ref.read(authControllerProvider).logout();
    }
  }
}

class _OwnerMenuItem extends StatelessWidget {
  const _OwnerMenuItem(
    this.value,
    this.icon,
    this.label, {
    this.danger = false,
  });
  final String value;
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: danger ? AppColors.red : AppColors.black),
    title: Text(
      label,
      style: TextStyle(color: danger ? AppColors.red : AppColors.black),
    ),
    onTap: () => Navigator.pop(context, value),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.controller,
    required this.resolver,
    required this.mediaPicker,
    required this.useInlineEditor,
    this.onMessage,
    this.onShare,
    this.onOwnerMenu,
  });
  final PublicUser user;
  final ProfileController controller;
  final MediaUrlResolver resolver;
  final MediaPickerService mediaPicker;
  final bool useInlineEditor;
  final VoidCallback? onMessage;
  final VoidCallback? onShare;
  final VoidCallback? onOwnerMenu;

  @override
  Widget build(BuildContext context) {
    final cover = resolver.resolve(user.coverUrl);
    final avatar = resolver.resolve(user.avatarUrl);
    if (MediaQuery.sizeOf(context).width.isFinite) {
      return _SourceProfileHeader(
        user: user,
        avatar: avatar,
        isOwner: controller.isOwner,
        profileBusy: controller.state.profileBusy,
        followBusy: controller.state.followBusy,
        onFollowers: () => _follows(context, true),
        onFollowing: () => _follows(context, false),
        onEdit: () => !useInlineEditor
            ? context.pushNamed(AppRoute.editProfile.name)
            : _edit(context),
        onAvatar: () => _pickImage(ProfileImageKind.avatar),
        onCover: () => _pickImage(ProfileImageKind.cover),
        onMessage: onMessage,
        onShare: onShare,
        onOwnerMenu: onOwnerMenu,
        onFollow: () => controller.toggleFollow().catchError((_) {}),
        onSafety: (type) => _confirmSafety(context, type),
      );
    }
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
                                      : () => context.pushNamed(
                                          AppRoute.editProfile.name,
                                        ),
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

  void _follows(BuildContext context, bool followers) => context.pushNamed(
    AppRoute.follows.name,
    pathParameters: {'id': user.id},
    queryParameters: {
      'tab': followers ? 'followers' : 'following',
      'name': user.displayName,
    },
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

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({
    required this.selected,
    required this.showSaved,
    required this.onSelected,
  });
  final ProfileTab selected;
  final bool showSaved;
  final ValueChanged<ProfileTab> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _ProfileTabButton(
        label: 'Bài viết',
        icon: Icons.grid_view_rounded,
        active: selected == ProfileTab.posts,
        onPressed: () => onSelected(ProfileTab.posts),
      ),
      if (showSaved) ...[
        const SizedBox(width: 42),
        _ProfileTabButton(
          label: 'Đã lưu',
          icon: Icons.bookmark_outline,
          active: selected == ProfileTab.saved,
          onPressed: () => onSelected(ProfileTab.saved),
        ),
      ],
    ],
  );
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    selected: active,
    child: InkWell(
      onTap: onPressed,
      child: SizedBox(
        width: 68,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22),
            if (active)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 42,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SourceProfileHeader extends StatelessWidget {
  const _SourceProfileHeader({
    required this.user,
    required this.avatar,
    required this.isOwner,
    required this.profileBusy,
    required this.followBusy,
    required this.onFollowers,
    required this.onFollowing,
    required this.onEdit,
    required this.onAvatar,
    required this.onCover,
    required this.onFollow,
    required this.onSafety,
    this.onMessage,
    this.onShare,
    this.onOwnerMenu,
  });

  final PublicUser user;
  final Uri? avatar;
  final bool isOwner;
  final bool profileBusy;
  final bool followBusy;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback onEdit;
  final VoidCallback onAvatar;
  final VoidCallback onCover;
  final VoidCallback onFollow;
  final ValueChanged<String> onSafety;
  final VoidCallback? onMessage;
  final VoidCallback? onShare;
  final VoidCallback? onOwnerMenu;

  String get _handle {
    final normalized = user.displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    return '@${normalized.isEmpty ? 'daily.meal' : normalized}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    tooltip: 'Quay lại',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.maybePop(context),
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(24),
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                    ),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 30 / 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      key: const Key('profile-owner-menu'),
                      tooltip: 'Mở menu hồ sơ',
                      onPressed: onOwnerMenu,
                      icon: const Icon(Icons.more_horiz, size: 26),
                    )
                  else
                    PopupMenuButton<String>(
                      tooltip: isOwner ? 'Mở menu hồ sơ' : 'An toàn tài khoản',
                      icon: const Icon(Icons.more_horiz, size: 26),
                      onSelected: (value) {
                        switch (value) {
                          case 'avatar':
                            onAvatar();
                          case 'cover':
                            onCover();
                          case 'blocked':
                            context.pushNamed(AppRoute.blocked.name);
                          case 'premium':
                            context.pushNamed(AppRoute.premium.name);
                          case 'settings':
                            context.pushNamed(AppRoute.settings.name);
                          case 'restrict':
                          case 'block':
                          case 'report':
                            onSafety(value);
                        }
                      },
                      itemBuilder: (_) => isOwner
                          ? const [
                              PopupMenuItem(
                                value: 'avatar',
                                child: Text('Đổi avatar'),
                              ),
                              PopupMenuItem(
                                value: 'cover',
                                child: Text('Đổi ảnh bìa'),
                              ),
                              PopupMenuItem(
                                value: 'blocked',
                                child: Text('Đã chặn'),
                              ),
                              PopupMenuItem(
                                value: 'premium',
                                child: Text('Daily Premium'),
                              ),
                              PopupMenuItem(
                                value: 'settings',
                                child: Text('Cài đặt'),
                              ),
                            ]
                          : [
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        key: const Key('profile-avatar-action'),
                        onTap: isOwner && !profileBusy ? onAvatar : null,
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.green,
                          backgroundImage: avatar == null
                              ? null
                              : NetworkImage(avatar.toString()),
                          child: avatar == null
                              ? Text(
                                  user.displayName.characters.first
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (user.isPremium)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.yellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'P',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
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
                        const SizedBox(height: 7),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _CompactCount(
                                user.counts.posts,
                                'Bài viết',
                              ),
                            ),
                            Expanded(
                              child: KeyedSubtree(
                                key: const Key('profile-followers-count'),
                                child: _CompactCount(
                                  user.counts.followers,
                                  'Theo dõi',
                                  onFollowers,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _CompactCount(
                                user.counts.following,
                                'Đang Theo Dõi',
                                onFollowing,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$_handle ',
                      style: const TextStyle(color: Color(0xFFA342FF)),
                    ),
                    TextSpan(
                      text:
                          user.bio ??
                          'Daily Meal creator chia sẻ món ngon mỗi ngày.',
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 20 / 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProfileAction(
                      key: const Key('profile-primary-action'),
                      label: isOwner ? 'Chỉnh sửa trang' : 'Nhắn tin',
                      onPressed: isOwner ? onEdit : onMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProfileAction(
                      key: const Key('profile-secondary-action'),
                      label: isOwner
                          ? 'Chia sẻ trang'
                          : user.relationship.isFollowing
                          ? 'Đang theo dõi'
                          : 'Theo dõi',
                      onPressed: isOwner
                          ? onShare
                          : followBusy
                          ? null
                          : onFollow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactCount extends StatelessWidget {
  const _CompactCount(this.value, this.label, [this.onTap]);
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    elevation: 4,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
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
  const _PostGrid({
    required this.posts,
    required this.resolver,
    required this.onOpen,
  });
  final List<FeedPost> posts;
  final MediaUrlResolver resolver;
  final ValueChanged<FeedPost> onOpen;
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
          maxCrossAxisExtent: 180,
          mainAxisExtent: 208,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
        ),
        itemCount: posts.length,
        itemBuilder: (_, index) {
          final post = posts[index];
          return DailyCompactPostPreview(
            key: Key('profile-post-${post.id}'),
            post: post,
            resolver: resolver,
            showAuthor: false,
            onOpen: () => onOpen(post),
          );
        },
      ),
    );
  }
}
