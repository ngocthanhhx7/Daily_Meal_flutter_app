import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/inbox_controller.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/messaging_providers.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({this.controller, this.mediaResolver, super.key});
  final InboxController? controller;
  final MediaUrlResolver? mediaResolver;
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxController? _owned;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null || _owned != null) return;
    _owned = InboxController(
      ref.read(messagingRepositoryProvider),
      ref.read(realtimeClientProvider),
    )..initialize().catchError((_) {});
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

  Widget _screen(InboxController controller) => AdaptiveScaffold(
    dailyMealStyle: true,
    destinations: const [
      AdaptiveDestination(icon: Icons.home_rounded, label: 'Trang chủ'),
      AdaptiveDestination(icon: Icons.search_rounded, label: 'Tìm kiếm'),
      AdaptiveDestination(icon: Icons.add_box_outlined, label: 'Đăng bài'),
      AdaptiveDestination(icon: Icons.chat_outlined, label: 'Tin nhắn'),
      AdaptiveDestination(icon: Icons.person_outline, label: 'Hồ sơ'),
    ],
    selectedIndex: 3,
    onDestinationSelected: (index) {
      if (index == 0) context.goNamed(AppRoute.home.name);
      if (index == 1) context.goNamed(AppRoute.search.name);
      if (index == 2) context.goNamed(AppRoute.createPost.name);
      if (index == 4) context.goNamed(AppRoute.profile.name);
    },
    body: DailyMealBackground(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.chat_bubble_outline_rounded),
              title: Text('Tin nhắn'),
              subtitle: Text('Các cuộc trò chuyện trong Daily Meal'),
            ),
            Expanded(
              child: _content(
                controller,
                widget.mediaResolver ?? ref.watch(mediaUrlResolverProvider),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content(InboxController controller, MediaUrlResolver resolver) {
    if (controller.loading && controller.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.conversations.isEmpty) {
      return Center(
        child: OutlinedButton(
          onPressed: () => controller.load().catchError((_) {}),
          child: const Text('Thử lại'),
        ),
      );
    }
    if (controller.conversations.isEmpty) {
      return const Center(
        child: Text('Chưa có tin nhắn. Hãy mở hồ sơ một người để bắt đầu.'),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final conversation = controller.conversations[index];
          final avatar = resolver.resolve(conversation.otherUser.avatarUrl);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: avatar == null
                    ? null
                    : NetworkImage(avatar.toString()),
                child: avatar == null
                    ? Text(conversation.otherUser.displayName.characters.first)
                    : null,
              ),
              title: Text(conversation.otherUser.displayName),
              subtitle: Text(
                conversation.lastMessage.body.isEmpty
                    ? 'Bắt đầu cuộc trò chuyện'
                    : conversation.lastMessage.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _open(conversation),
            ),
          );
        },
      ),
    );
  }

  void _open(Conversation conversation) => context.pushNamed(
    AppRoute.chat.name,
    pathParameters: {'id': conversation.id},
    extra: conversation.otherUser,
  );
}
