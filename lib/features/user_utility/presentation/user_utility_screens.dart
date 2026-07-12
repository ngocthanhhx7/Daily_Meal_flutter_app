import 'dart:async';

import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/auth/services/social_identity_provider.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_controller.dart';
import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_providers.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _UtilityScaffold(
    title: 'Cài đặt',
    child: ListView(
      children: [
        _section(context, 'Tài khoản của bạn', [
          _tile(
            Icons.person_outline,
            'Trung tâm tài khoản',
            () => context.goNamed(AppRoute.profile.name),
          ),
          _tile(
            Icons.workspace_premium_outlined,
            'Daily Premium',
            () => context.pushNamed(AppRoute.premium.name),
          ),
          _tile(
            Icons.password_outlined,
            'Đổi mật khẩu',
            () => context.pushNamed(AppRoute.changePassword.name),
          ),
          const _GoogleLinkTile(),
        ]),
        _section(context, 'Cách bạn dùng Daily Meal', [
          _tile(
            Icons.bookmark_outline,
            'Đã lưu',
            () => context.pushNamed(AppRoute.saved.name),
          ),
          _tile(
            Icons.collections_outlined,
            'Tổng hợp bài đăng',
            () => context.pushNamed(AppRoute.postSummary.name),
          ),
          _tile(
            Icons.notifications_outlined,
            'Thông báo',
            () => context.pushNamed(AppRoute.notifications.name),
          ),
          _tile(
            Icons.bar_chart_outlined,
            'Theo dõi tiến độ đăng bài',
            () => context.pushNamed(AppRoute.progress.name),
          ),
          _tile(
            Icons.block_outlined,
            'Đã chặn',
            () => context.pushNamed(AppRoute.blocked.name),
          ),
        ]),
        _section(context, 'Trợ giúp', [
          _tile(
            Icons.help_outline,
            'Hỗ trợ',
            () => context.pushNamed(AppRoute.support.name),
          ),
          _tile(
            Icons.group_outlined,
            'Chia sẻ tài khoản',
            () => context.pushNamed(AppRoute.shareAccount.name),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.tonalIcon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ),
      ],
    ),
  );
  static Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
          ),
          ...children,
        ],
      ),
    ),
  );
  static Widget _tile(IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        minTileHeight: 48,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng Daily Meal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authControllerProvider).logout();
  }
}

class _GoogleLinkTile extends ConsumerStatefulWidget {
  const _GoogleLinkTile();
  @override
  ConsumerState<_GoogleLinkTile> createState() => _GoogleLinkTileState();
}

class _GoogleLinkTileState extends ConsumerState<_GoogleLinkTile> {
  late final SocialIdentityProvider identity;
  StreamSubscription<String>? subscription;
  bool ready = false, busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    identity = PluginSocialIdentityProvider();
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    try {
      subscription = identity.googleIdTokens.listen(_link);
      final config = ref.read(appConfigProvider);
      await identity.initialize(
        googleWebClientId: config.googleWebClientId,
        facebookAppId: config.facebookAppId,
      );
      if (mounted) setState(() => ready = true);
    } catch (value) {
      if (mounted) setState(() => error = value.toString());
    }
  }

  Future<void> _link(String token) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final user = await ref
          .read(userUtilityControllerProvider)
          .linkGoogle(token);
      ref.read(authControllerProvider).updateUser(user);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã liên kết Google.')));
      }
    } catch (value) {
      if (mounted) setState(() => error = value.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    identity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        minTileHeight: 48,
        leading: const Icon(Icons.link),
        title: const Text('Liên kết Google'),
        subtitle: error == null
            ? const Text('Dùng Google để đăng nhập lần sau')
            : Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AbsorbPointer(
          absorbing: !ready || busy,
          child: Opacity(
            opacity: ready && !busy ? 1 : .5,
            child: identity.googleButton(enabled: ready && !busy),
          ),
        ),
      ),
    ],
  );
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({this.controller, super.key});
  final UserUtilityController? controller;
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserUtilityController controller;
    if (widget.controller case final injected?) {
      controller = injected;
    } else {
      controller = ref.watch(userUtilityControllerProvider);
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) => _UtilityScaffold(
        title: 'Đổi mật khẩu',
        child: ListView(
          children: [
            TextField(
              key: const Key('current-password'),
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('new-password'),
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('confirm-password'),
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
              ),
            ),
            if (controller.errorMessage case final error?)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: controller.busy
                  ? null
                  : () async {
                      try {
                        if (await controller.changePassword(
                              current.text,
                              next.text,
                              confirm.text,
                            ) &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đổi mật khẩu.')),
                          );
                          context.pop();
                        }
                      } catch (_) {}
                    },
              child: controller.busy
                  ? const CircularProgressIndicator()
                  : const Text('Cập nhật mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}

class PostSummaryScreen extends ConsumerStatefulWidget {
  const PostSummaryScreen({super.key});
  @override
  ConsumerState<PostSummaryScreen> createState() => _PostSummaryScreenState();
}

class _PostSummaryScreenState extends ConsumerState<PostSummaryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(userUtilityControllerProvider)
          .loadSummary()
          .catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(userUtilityControllerProvider);
    return ListenableBuilder(
      listenable: c,
      builder: (_, _) => _UtilityScaffold(
        title: 'Tổng hợp bài đăng',
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<PostSummaryFilter>(
                segments: [
                  for (final f in PostSummaryFilter.values)
                    ButtonSegment(value: f, label: Text(f.label)),
                ],
                selected: {c.filter},
                onSelectionChanged: (v) =>
                    c.loadSummary(selected: v.first).catchError((_) {}),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _PostsGrid(
                posts: c.posts,
                loading: c.loading,
                error: c.errorMessage,
              ),
            ),
            if (c.hasMore)
              TextButton(
                onPressed: c.loadingMore
                    ? null
                    : () => c.loadMore().catchError((_) {}),
                child: Text(c.loadingMore ? 'Đang tải…' : 'Tải thêm'),
              ),
          ],
        ),
      ),
    );
  }
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final id = ref.read(authControllerProvider).state.user?.id;
      if (id != null) {
        ref
            .read(userUtilityControllerProvider)
            .loadProgress(id)
            .catchError((_) {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(userUtilityControllerProvider);
    final likes = c.progressPosts.fold(0, (s, p) => s + p.likes);
    final comments = c.progressPosts.fold(0, (s, p) => s + p.comments);
    return ListenableBuilder(
      listenable: c,
      builder: (_, _) => _UtilityScaffold(
        title: 'Theo dõi tiến độ',
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.article_outlined),
                  label: Text('${c.progressPosts.length} bài'),
                ),
                Chip(
                  avatar: const Icon(Icons.favorite_outline),
                  label: Text('$likes lượt thích'),
                ),
                Chip(
                  avatar: const Icon(Icons.chat_bubble_outline),
                  label: Text('$comments bình luận'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _PostsGrid(
                posts: c.progressPosts,
                loading: c.loading,
                error: c.errorMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final subject = TextEditingController(), message = TextEditingController();
  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _UtilityScaffold(
    title: 'Hỗ trợ',
    child: ListView(
      children: [
        const ExpansionTile(
          title: Text('Làm thế nào để dùng Daily Meal trên điện thoại?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Cài app Android, đăng nhập và cấp quyền ảnh/camera khi bạn muốn đăng món ăn.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Làm sao để chia sẻ tài khoản?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'API nhóm gia đình đang được chuẩn bị và chưa mở trên production.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: subject,
          decoration: const InputDecoration(labelText: 'Tiêu đề'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: message,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Nội dung'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            final text =
                subject.text.trim().isEmpty || message.text.trim().isEmpty
                ? 'Vui lòng nhập đầy đủ tiêu đề và nội dung.'
                : 'Kênh gửi phản hồi trực tiếp đang được chuẩn bị; nội dung chưa được gửi.';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(text)));
          },
          child: const Text('Gửi phản hồi'),
        ),
      ],
    ),
  );
}

class ShareAccountScreen extends ConsumerWidget {
  const ShareAccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium =
        ref.watch(authControllerProvider).state.user?.isPremium == true;
    final status = premium
        ? 'Tính năng đang chuẩn bị'
        : 'Nâng cấp Premium để lấy mã';
    return _UtilityScaffold(
      title: 'Chia sẻ tài khoản',
      child: ListView(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.groups_2_outlined, size: 44),
                  Text(
                    'Nhóm Gia Đình Daily Meal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Chia sẻ quyền lợi Premium với tối đa 5 thành viên khi backend mở API nhóm gia đình.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: const Text('Mã chia sẻ của bạn'),
            subtitle: Text(status),
            trailing: const Icon(Icons.copy_outlined),
            onTap: () {
              Clipboard.setData(ClipboardData(text: status));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'API mã gia đình chưa được mở trên production.',
                  ),
                ),
              );
            },
          ),
          if (!premium)
            FilledButton(
              onPressed: () => context.pushNamed(AppRoute.premium.name),
              child: const Text('Nâng cấp Daily Premium'),
            ),
        ],
      ),
    );
  }
}

class _PostsGrid extends ConsumerWidget {
  const _PostsGrid({required this.posts, required this.loading, this.error});
  final List<SummaryPost> posts;
  final bool loading;
  final String? error;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && posts.isEmpty) return Center(child: Text(error!));
    if (posts.isEmpty) {
      return const Center(child: Text('Chưa có bài đăng phù hợp.'));
    }
    final resolver = ref.watch(mediaUrlResolverProvider);
    return LayoutBuilder(
      builder: (_, constraints) {
        final count = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 3
            : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .78,
          ),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final post = posts[i];
            final image = resolver.resolve(post.imageUrl);
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: image == null
                        ? const ColoredBox(
                            color: Color(0xFFE8EFE8),
                            child: Center(child: Icon(Icons.restaurant)),
                          )
                        : Image.network(
                            image.toString(),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      post.caption.isEmpty
                          ? 'Món ngon Daily Meal'
                          : post.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Text(
                      '${post.authorName} • ♥ ${post.likes} • 💬 ${post.comments}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _UtilityScaffold extends StatelessWidget {
  const _UtilityScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}
