import 'dart:async';

import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/auth/services/social_identity_provider.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_controller.dart';
import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_providers.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:flutter/material.dart';
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
            () => context.pushNamed(AppRoute.editProfile.name),
          ),
          _tile(
            Icons.workspace_premium_outlined,
            'Daily Premium',
            () => context.pushNamed(AppRoute.premium.name),
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
        _section(context, '', [
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
          _tile(
            Icons.workspace_premium_outlined,
            'Quyền lợi',
            () => context.pushNamed(AppRoute.premium.name),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppColors.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.yellow),
            ),
            child: ListTile(
              minTileHeight: 48,
              onTap: () => _confirmLogout(context, ref),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  static Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
          ),
        for (final child in children)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color:
                      title == 'Tài khoản của bạn' &&
                          children.indexOf(child) == 1
                      ? AppColors.yellow
                      : AppColors.line,
                  width:
                      title == 'Tài khoản của bạn' &&
                          children.indexOf(child) == 1
                      ? 2
                      : 1,
                ),
              ),
              child: child,
            ),
          ),
      ],
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
            _SummarySegments(
              selected: c.filter,
              onSelected: (value) =>
                  c.loadSummary(selected: value).catchError((_) {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _PostsGrid(
                posts: c.posts,
                loading: c.loading,
                error: c.errorMessage,
                onOpen: (post) => context.goNamed(
                  AppRoute.home.name,
                  queryParameters: {'postId': post.id},
                ),
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
            const Text(
              'Tổng',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$comments',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chat_bubble_outline, size: 14),
                  const SizedBox(width: 12),
                  Text(
                    '$likes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.favorite, size: 15, color: AppColors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _PostsGrid(
                posts: c.progressPosts,
                loading: c.loading,
                error: c.errorMessage,
                onOpen: (post) => context.goNamed(
                  AppRoute.home.name,
                  queryParameters: {'postId': post.id},
                ),
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
        const _SectionLabel('Câu hỏi thường gặp (FAQs)'),
        const _FaqCard(
          question: '1. Làm thế nào để thêm Locket Widget trên iOS?',
          answer:
              'Nhấn giữ màn hình chính của iPhone → Chọn dấu "+" ở góc trái → Tìm "Daily Meal" và chọn Thêm tiện ích (Add Widget).',
        ),
        const SizedBox(height: 12),
        const _FaqCard(
          question: '2. Làm sao để chia sẻ tài khoản?',
          answer:
              'Bạn hãy nâng cấp gói Daily Premium để kích hoạt mã chia sẻ cho gia đình và bạn bè dùng chung quyền lợi!',
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Gửi phản hồi cho chúng tôi'),
        TextField(
          controller: subject,
          decoration: const InputDecoration(
            labelText: 'Tiêu đề',
            hintText: 'VD: Lỗi kết nối tài khoản',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: message,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Nội dung',
            hintText: 'Mô tả chi tiết vấn đề hoặc ý kiến của bạn...',
          ),
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

class ShareAccountScreen extends ConsumerStatefulWidget {
  const ShareAccountScreen({super.key});
  @override
  ConsumerState<ShareAccountScreen> createState() => _ShareAccountScreenState();
}

class _ShareAccountScreenState extends ConsumerState<ShareAccountScreen> {
  final inviteCode = TextEditingController();

  @override
  void dispose() {
    inviteCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium =
        ref.watch(authControllerProvider).state.user?.isPremium == true;
    final status = premium
        ? 'Tính năng đang chuẩn bị'
        : 'Nâng cấp Premium để lấy mã';
    return _UtilityScaffold(
      title: 'Chia sẻ tài khoản',
      child: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: .08),
              border: Border.all(color: AppColors.green),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    size: 32,
                    color: AppColors.greenDark,
                  ),
                  Text(
                    'Nhóm Gia Đình Daily Meal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Tính năng này cho phép bạn chia sẻ tài khoản Premium với tối đa 5 thành viên trong gia đình để cùng nhau chia sẻ công thức và lưu trữ khoảnh khắc!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Mã chia sẻ của bạn'),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line, width: 1.5),
            ),
            tileColor: AppColors.canvasStrong,
            title: Text(status),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    premium
                        ? 'API mã gia đình chưa được mở trên production.'
                        : 'Vui lòng nâng cấp tài khoản Premium để sử dụng tính năng này!',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            premium
                ? 'Tính năng tạo mã chia sẻ cho tài khoản Premium đang được chuẩn bị.'
                : 'Nâng cấp lên Daily Premium để tạo mã chia sẻ tài khoản với người thân.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Nhập mã chia sẻ được tặng'),
          TextField(
            controller: inviteCode,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Mã gia đình',
              hintText: 'VD: DMEAL-XXXXXX',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  inviteCode.text.trim().isEmpty
                      ? 'Vui lòng nhập mã chia sẻ để tham gia.'
                      : 'Mã chia sẻ gia đình chưa kết nối với server trong bản này, nên Daily Meal chưa thể tham gia nhóm hoặc kích hoạt Premium từ mã.',
                ),
              ),
            ),
            child: const Text('Tham gia nhóm'),
          ),
        ],
      ),
    );
  }
}

class _SummarySegments extends StatelessWidget {
  const _SummarySegments({required this.selected, required this.onSelected});
  final PostSummaryFilter selected;
  final ValueChanged<PostSummaryFilter> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        for (final filter in PostSummaryFilter.values)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(filter),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                constraints: const BoxConstraints(minHeight: 34),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected == filter
                      ? AppColors.yellow
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  filter.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected == filter
                        ? AppColors.black
                        : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _PostsGrid extends ConsumerWidget {
  const _PostsGrid({
    required this.posts,
    required this.loading,
    required this.onOpen,
    this.error,
  });
  final List<SummaryPost> posts;
  final bool loading;
  final String? error;
  final ValueChanged<SummaryPost> onOpen;
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
    final left = [for (var i = 0; i < posts.length; i += 2) posts[i]];
    final right = [for (var i = 1; i < posts.length; i += 2) posts[i]];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final post in left) ...[
                  _SummaryPostCard(
                    post: post,
                    image: resolver.resolve(post.imageUrl),
                    onTap: () => onOpen(post),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Column(
                children: [
                  for (final post in right) ...[
                    _SummaryPostCard(
                      post: post,
                      image: resolver.resolve(post.imageUrl),
                      onTap: () => onOpen(post),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPostCard extends StatelessWidget {
  const _SummaryPostCard({
    required this.post,
    required this.image,
    required this.onTap,
  });
  final SummaryPost post;
  final Uri? image;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: .78,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: image == null
                ? const ColoredBox(
                    color: AppColors.canvasStrong,
                    child: Center(
                      child: Icon(Icons.restaurant, color: AppColors.green),
                    ),
                  )
                : Image.network(
                    image.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.canvasStrong,
                      child: Center(child: Icon(Icons.image_outlined)),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          post.caption.isEmpty ? 'Nó ngon...' : post.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '${post.authorName}  ♥ ${post.likes}  💬 ${post.comments}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _UtilityScaffold extends StatelessWidget {
  const _UtilityScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: DailyMealBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.chevron_left, size: 24),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 25,
                              height: 1.24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(color: AppColors.muted, fontSize: 13),
      ),
    ),
  );
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.question, required this.answer});
  final String question, answer;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 13,
            height: 18 / 13,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}
