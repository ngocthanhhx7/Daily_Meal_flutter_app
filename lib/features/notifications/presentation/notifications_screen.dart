import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_controller.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_providers.dart';
import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({this.controller, super.key});
  final NotificationsController? controller;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationsController value =
        controller ?? ref.watch(notificationsControllerProvider);
    final body = controller == null
        ? _body(context, ref, value)
        : AnimatedBuilder(
            animation: value,
            builder: (_, _) => _body(context, ref, value),
          );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (value.unreadCount > 0)
            TextButton(
              onPressed: () => value.markAllRead().catchError((_) {}),
              child: const Text('Đọc tất cả'),
            ),
          if (value.notifications.isNotEmpty)
            IconButton(
              tooltip: 'Xóa tất cả',
              onPressed: () => _deleteAll(context, value),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: body,
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
            child: Card(
              color: item.read
                  ? AppColors.surface
                  : Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: CircleAvatar(child: Icon(_icon(item.type))),
                title: Text(item.sender?.displayName ?? 'Daily Meal'),
                subtitle: Text(item.body),
                trailing: item.read ? null : const Icon(Icons.circle, size: 10),
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
        context.goNamed(AppRoute.home.name);
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
