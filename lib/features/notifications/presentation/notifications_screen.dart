import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_controller.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_providers.dart';
import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/web_push_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({
    this.controller,
    this.webPushController,
    super.key,
  });
  final NotificationsController? controller;
  final WebPushController? webPushController;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationsController value =
        controller ?? ref.watch(notificationsControllerProvider);
    final push =
        webPushController ??
        (controller == null ? ref.watch(webPushControllerProvider) : null);
    final body = controller == null
        ? _body(context, ref, value)
        : AnimatedBuilder(
            animation: value,
            builder: (_, _) => _body(context, ref, value),
          );
    return Scaffold(
      body: DailyMealBackground(
        child: SafeArea(
          child: Column(
            children: [
              const _NotificationHeader(),
              if (push != null) _WebPushBanner(controller: push),
              if (value.notifications.isNotEmpty)
                _NotificationToolbar(
                  count: value.notifications.length,
                  unreadCount: value.unreadCount,
                  onReadAll: () => value.markAllRead().catchError((_) {}),
                  onDeleteAll: () => _deleteAll(context, value),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    NotificationsController controller,
  ) {
    if (controller.loading && controller.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.notifications.isEmpty) {
      return Center(
        child: OutlinedButton(
          onPressed: () => controller.load().catchError((_) {}),
          child: const Text('Thử lại'),
        ),
      );
    }
    if (controller.notifications.isEmpty) {
      return const Center(child: Text('Bạn chưa có thông báo nào.'));
    }
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final item = controller.notifications[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: const ColoredBox(
              color: AppColors.red,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
            onDismissed: (_) => controller.delete(item.id).catchError((_) {}),
            child: Material(
              color: item.read ? AppColors.surface : AppColors.canvasStrong,
              borderRadius: BorderRadius.circular(10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: CircleAvatar(
                  backgroundColor: _color(item.type).withValues(alpha: .10),
                  child: Icon(_icon(item.type), color: _color(item.type)),
                ),
                title: Text(item.sender?.displayName ?? 'Daily Meal'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.body),
                    const SizedBox(height: 3),
                    Text(
                      _relativeTime(item.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!item.read)
                      const Icon(Icons.circle, size: 9, color: AppColors.green),
                    IconButton(
                      key: Key('delete-notification-${item.id}'),
                      tooltip: 'Xóa thông báo',
                      onPressed: () =>
                          controller.delete(item.id).catchError((_) {}),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
                onTap: () => _open(context, ref, controller, item),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _icon(NotificationType type) => switch (type) {
    NotificationType.like => Icons.favorite_rounded,
    NotificationType.comment => Icons.chat_bubble_rounded,
    NotificationType.follow => Icons.person_add_alt_1_rounded,
    NotificationType.message => Icons.mail_rounded,
  };

  Color _color(NotificationType type) => switch (type) {
    NotificationType.like => AppColors.red,
    NotificationType.comment => AppColors.greenDark,
    NotificationType.follow => AppColors.green,
    NotificationType.message => AppColors.yellow,
  };

  String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NotificationsController controller,
    AppNotification item,
  ) async {
    await controller.markRead(item.id).catchError((_) {});
    if (!context.mounted) return;
    switch (notificationDestination(item)) {
      case NotificationDestination.publicProfile:
        context.pushNamed(
          AppRoute.publicProfile.name,
          pathParameters: {'id': item.sender!.id},
        );
      case NotificationDestination.inbox:
        context.pushNamed(AppRoute.inbox.name);
      case NotificationDestination.home:
        context.goNamed(
          AppRoute.home.name,
          queryParameters: item.postId == null
              ? const {}
              : {'postId': item.postId!},
        );
      case NotificationDestination.comments:
        context.pushNamed(
          AppRoute.comments.name,
          pathParameters: {'id': item.postId!},
        );
      case NotificationDestination.recipe:
        context.pushNamed(
          AppRoute.recipe.name,
          pathParameters: {'id': item.postId!},
        );
    }
  }

  Future<void> _deleteAll(
    BuildContext context,
    NotificationsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteAll().catchError((_) {});
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 36,
          child: IconButton(
            tooltip: 'Quay lại',
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Thông báo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _NotificationToolbar extends StatelessWidget {
  const _NotificationToolbar({
    required this.count,
    required this.unreadCount,
    required this.onReadAll,
    required this.onDeleteAll,
  });
  final int count, unreadCount;
  final VoidCallback onReadAll, onDeleteAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Bạn có '),
              TextSpan(
                text: '$count',
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' thông báo'),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: unreadCount > 0 ? onReadAll : null,
              icon: Icon(
                unreadCount > 0 ? Icons.done_all_outlined : Icons.check_circle,
                size: 16,
              ),
              label: Text(unreadCount > 0 ? 'Đọc tất cả' : 'Đã đọc hết'),
            ),
            TextButton.icon(
              onPressed: onDeleteAll,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Xóa tất cả'),
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
            ),
          ],
        ),
      ],
    ),
  );
}

class _WebPushBanner extends StatelessWidget {
  const _WebPushBanner({required this.controller});
  final WebPushController controller;
  @override
  Widget build(BuildContext context) {
    if (controller.status == WebPushStatus.unsupported ||
        controller.status == WebPushStatus.ready) {
      return const SizedBox.shrink();
    }
    final text = switch (controller.status) {
      WebPushStatus.needsPermission =>
        'Bật thông báo trình duyệt để nhận cập nhật khi Daily Meal không mở.',
      WebPushStatus.permissionDenied =>
        'Quyền thông báo đang bị chặn trong cài đặt trình duyệt.',
      WebPushStatus.missingPublicKey => 'Máy chủ chưa cấu hình Web Push VAPID.',
      WebPushStatus.failure => 'Không thể đăng ký Web Push.',
      _ => 'Đang kiểm tra Web Push...',
    };
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(text),
        trailing:
            controller.status == WebPushStatus.needsPermission ||
                controller.status == WebPushStatus.failure
            ? FilledButton.tonal(
                onPressed: controller.status == WebPushStatus.loading
                    ? null
                    : () => controller.enable().catchError((_) {}),
                child: const Text('Bật'),
              )
            : null,
      ),
    );
  }
}
