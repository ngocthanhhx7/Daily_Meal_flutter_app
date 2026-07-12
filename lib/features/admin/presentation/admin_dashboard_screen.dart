import 'dart:math' as math;

import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/app_error_view.dart';
import 'package:daily_meal_flutter_app/core/widgets/app_loading_view.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_dashboard_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_providers.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_management_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_analytics_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:daily_meal_flutter_app/features/admin/presentation/widgets/admin_scaffold.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({
    this.controller,
    this.managementController,
    this.analyticsController,
    this.onLogout,
    super.key,
  });
  final AdminDashboardController? controller;
  final AdminManagementController? managementController;
  final AdminAnalyticsController? analyticsController;
  final VoidCallback? onLogout;

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _destination = 0;

  @override
  Widget build(BuildContext context) {
    final AdminDashboardController controller;
    if (widget.controller case final injected?) {
      controller = injected;
    } else {
      controller = ref.watch(adminDashboardControllerProvider);
    }
    final AdminManagementController management;
    if (widget.managementController case final injected?) {
      management = injected;
    } else {
      management = ref.watch(adminManagementControllerProvider);
    }
    final AdminAnalyticsController analytics;
    if (widget.analyticsController case final injected?) {
      analytics = injected;
    } else {
      analytics = ref.watch(adminAnalyticsControllerProvider);
    }
    return ListenableBuilder(
      listenable: Listenable.merge([controller, management, analytics]),
      builder: (context, _) => AdminScaffold(
        selectedIndex: _destination,
        onDestinationSelected: (value) {
          setState(() => _destination = value);
          final future = switch (value) {
            1 || 2 || 6 => analytics.load(),
            3 => management.loadPosts(),
            4 => management.loadReports(),
            5 => management.loadPayments(),
            7 => management.loadUsers(),
            _ => Future<void>.value(),
          };
          future.catchError((_) {});
        },
        onRefresh: () {
          final future = switch (_destination) {
            0 => controller.load(),
            1 || 2 || 6 => analytics.load(),
            3 => management.loadPosts(),
            4 => management.loadReports(),
            5 => management.loadPayments(),
            7 => management.loadUsers(),
            _ => Future<void>.value(),
          };
          future.catchError((_) {});
        },
        onLogout:
            widget.onLogout ?? () => ref.read(authControllerProvider).logout(),
        destinations: const [
          AdminDestination(icon: Icons.dashboard_outlined, label: 'Tổng quan'),
          AdminDestination(
            icon: Icons.schedule_outlined,
            label: 'Analytics 24h',
          ),
          AdminDestination(icon: Icons.speed_outlined, label: 'KPI'),
          AdminDestination(icon: Icons.article_outlined, label: 'Bài đăng'),
          AdminDestination(icon: Icons.flag_outlined, label: 'Báo cáo'),
          AdminDestination(icon: Icons.payments_outlined, label: 'Thanh toán'),
          AdminDestination(
            icon: Icons.auto_awesome_outlined,
            label: 'Báo cáo AI',
          ),
          AdminDestination(icon: Icons.people_outline, label: 'Người dùng'),
        ],
        body: switch (_destination) {
          0 => _DashboardBody(
            controller: controller,
            onLogout:
                widget.onLogout ??
                () => ref.read(authControllerProvider).logout(),
          ),
          1 || 2 || 6 => _AnalyticsSection(
            controller: analytics,
            destination: _destination,
          ),
          3 => _PostsSection(controller: management),
          4 => _ReportsSection(controller: management),
          5 => _PaymentsSection(controller: management),
          _ => _UsersSection(controller: management),
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.controller, required this.onLogout});
  final AdminDashboardController controller;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final dashboard = controller.dashboard;
    if (dashboard == null && controller.loading) return const AppLoadingView();
    if (dashboard == null && controller.errorMessage != null) {
      return AppErrorView(
        message: controller.errorMessage!,
        onRetry: () => controller.load().catchError((_) {}),
      );
    }
    if (dashboard == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Meal Admin',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Theo dõi vận hành và tăng trưởng theo thời gian thực',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<AdminRange>(
                        value: controller.range,
                        onChanged: controller.loading
                            ? null
                            : (range) {
                                if (range != null) {
                                  controller
                                      .load(selectedRange: range)
                                      .catchError((_) {});
                                }
                              },
                        items: [
                          for (final range in AdminRange.values)
                            DropdownMenuItem(
                              value: range,
                              child: Text(range.label),
                            ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Đăng xuất Admin',
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 900 ? 3 : 2;
                return SliverGrid.count(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: columns == 2 ? .95 : 1.75,
                  children: [
                    _KpiCard(
                      label: 'Tổng người dùng',
                      value: '${dashboard.allTime.users}',
                      delta: '+${dashboard.inRange.users}',
                      icon: Icons.people,
                    ),
                    _KpiCard(
                      label: 'Tổng bài viết',
                      value: '${dashboard.allTime.posts}',
                      delta: '+${dashboard.inRange.posts}',
                      icon: Icons.article,
                    ),
                    _KpiCard(
                      label: 'Tương tác',
                      value:
                          '${dashboard.allTime.comments + dashboard.allTime.likes + dashboard.allTime.saves}',
                      delta:
                          '+${dashboard.inRange.comments + dashboard.inRange.likes + dashboard.inRange.saves}',
                      icon: Icons.favorite_outline,
                    ),
                    _KpiCard(
                      label: 'Doanh thu',
                      value: _money(dashboard.allTime.revenue),
                      delta: _money(dashboard.inRange.revenue),
                      icon: Icons.payments,
                    ),
                    _KpiCard(
                      label: 'Báo cáo đang mở',
                      value: '${dashboard.allTime.openReports}',
                      delta: '${dashboard.inRange.openReports} trong kỳ',
                      icon: Icons.flag,
                    ),
                    _KpiCard(
                      label: 'Bữa ăn AI',
                      value: '${dashboard.allTime.meals}',
                      delta: '+${dashboard.inRange.meals}',
                      icon: Icons.auto_awesome_outlined,
                    ),
                  ],
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverToBoxAdapter(
              child: _TrendCard(points: dashboard.daily),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: _BreakdownsCard(value: dashboard.breakdowns),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: _RecentActivityCard(items: dashboard.recent),
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double value) => '${value.round()} ₫';
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
  });
  final String label, value, delta;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, height: 1.2),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  delta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});
  final List<AdminDailyPoint> points;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xu hướng tương tác',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Semantics(
            label:
                'Biểu đồ tương tác ${points.map((e) => '${e.date}: ${e.interactions}').join(', ')}',
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  points,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.color);
  final List<AdminDailyPoint> points;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = color.withValues(alpha: .15)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axis);
    }
    if (points.isEmpty) return;
    final maxValue = math.max(
      1,
      points.map((e) => e.interactions).reduce(math.max),
    );
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final y =
          size.height - (points[i].interactions / maxValue) * (size.height - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

class _BreakdownsCard extends StatelessWidget {
  const _BreakdownsCard({required this.value});
  final AdminBreakdowns value;
  @override
  Widget build(BuildContext context) {
    final groups = {
      'Gói người dùng': value.usersByPremium,
      'Trạng thái bài viết': value.postsByModeration,
      'Trạng thái thanh toán': value.paymentsByStatus,
      'Trạng thái báo cáo': value.reportsByStatus,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân bổ vận hành',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                for (final group in groups.entries)
                  SizedBox(
                    width: 230,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.key,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        for (final item in group.value)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.label),
                            trailing: Text('${item.count}'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});
  final List<AdminRecentItem> items;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động gần đây',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (items.isEmpty) const Text('Chưa có hoạt động gần đây'),
          for (final item in items.take(12))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (item.kind) {
                'reports' => Icons.flag_outlined,
                'posts' => Icons.article_outlined,
                'payments' => Icons.payments_outlined,
                _ => Icons.history,
              }),
              title: Text(_recentTitle(item)),
              subtitle: Text(item.data['createdAt']?.toString() ?? ''),
            ),
        ],
      ),
    ),
  );

  static String _recentTitle(AdminRecentItem item) => switch (item.kind) {
    'reports' =>
      item.data['note']?.toString().isNotEmpty == true
          ? item.data['note'].toString()
          : 'Báo cáo mới',
    'posts' =>
      item.data['caption']?.toString().isNotEmpty == true
          ? item.data['caption'].toString()
          : 'Bài viết mới',
    'payments' =>
      '${item.data['amount'] ?? 0} ${item.data['currency'] ?? 'VND'} • ${item.data['status'] ?? ''}',
    _ =>
      '${item.data['action'] ?? 'Admin action'} • ${item.data['adminEmail'] ?? ''}',
  };
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.title,
    required this.controller,
    required this.child,
    this.onSearch,
    this.filter,
  });
  final String title;
  final AdminManagementController controller;
  final Widget child;
  final ValueChanged<String>? onSearch;
  final Widget? filter;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ?filter,
          ],
        ),
      ),
      if (onSearch != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SearchBar(
            hintText: 'Tìm kiếm',
            leading: const Icon(Icons.search),
            onSubmitted: onSearch,
          ),
        ),
      if (controller.loading) const LinearProgressIndicator(),
      if (controller.errorMessage case final message?)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      Expanded(child: child),
    ],
  );
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({required this.controller});
  final AdminManagementController controller;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: 'Quản lý người dùng',
    controller: controller,
    onSearch: (q) => controller.loadUsers(search: q).catchError((_) {}),
    child: Column(
      children: [
        _InsightStrip(data: controller.userInsights),
        Expanded(
          child: _PagedList(
            page: controller.userPage,
            empty: 'Không có người dùng',
            onPage: (p) => controller.loadUsers(page: p).catchError((_) {}),
            itemBuilder: (user) => Card(
              child: ListTile(
                onTap: () async {
                  await controller.loadUserDetail(user.id).catchError((_) {});
                  if (context.mounted &&
                      controller.selectedUserDetail != null) {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => _UserDetailDialog(
                        data: controller.selectedUserDetail!,
                      ),
                    );
                  }
                },
                leading: CircleAvatar(
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email.isNotEmpty ? user.email : user.phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.isPremium)
                      const Icon(Icons.workspace_premium, color: Colors.amber),
                    Switch(
                      value: user.isPremium,
                      onChanged: controller.isMutating(user.id)
                          ? null
                          : (value) => controller
                                .setPremium(user, value)
                                .catchError((_) {}),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PostsSection extends StatelessWidget {
  const _PostsSection({required this.controller});
  final AdminManagementController controller;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: 'Kiểm duyệt bài viết',
    controller: controller,
    onSearch: (q) => controller.loadPosts(search: q).catchError((_) {}),
    filter: DropdownButton<String>(
      value: controller.moderationStatus ?? 'all',
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
        DropdownMenuItem(value: 'visible', child: Text('Hiển thị')),
        DropdownMenuItem(value: 'review', child: Text('Cần duyệt')),
        DropdownMenuItem(value: 'hidden', child: Text('Đã ẩn')),
      ],
      onChanged: (value) => controller
          .loadPosts(
            status: value == 'all' ? null : value,
            clearStatus: value == 'all',
          )
          .catchError((_) {}),
    ),
    child: Column(
      children: [
        _InsightStrip(data: controller.postInsights),
        Expanded(
          child: _PagedList(
            page: controller.postPage,
            empty: 'Không có bài viết',
            onPage: (p) => controller.loadPosts(page: p).catchError((_) {}),
            itemBuilder: (post) => Card(
              child: ListTile(
                title: Text(
                  post.caption.isEmpty ? '(Không có nội dung)' : post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${post.authorName} • ${post.visibility} • ${post.interactions} tương tác',
                ),
                trailing: PopupMenuButton<String>(
                  enabled: !controller.isMutating(post.id),
                  initialValue: post.moderationStatus,
                  onSelected: (value) =>
                      controller.moderate(post, value).catchError((_) {}),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'visible', child: Text('Hiển thị')),
                    PopupMenuItem(value: 'review', child: Text('Cần duyệt')),
                    PopupMenuItem(value: 'hidden', child: Text('Ẩn bài')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({required this.controller});
  final AdminManagementController controller;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: 'Báo cáo vi phạm',
    controller: controller,
    filter: DropdownButton<String>(
      value: controller.reportStatus,
      items: const [
        DropdownMenuItem(value: 'open', child: Text('Đang mở')),
        DropdownMenuItem(value: 'resolved', child: Text('Đã xử lý')),
        DropdownMenuItem(value: 'dismissed', child: Text('Bỏ qua')),
        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
      ],
      onChanged: (value) {
        if (value != null) {
          controller.loadReports(status: value).catchError((_) {});
        }
      },
    ),
    child: _PagedList(
      page: controller.reportPage,
      empty: 'Không có báo cáo',
      onPage: (p) => controller.loadReports(page: p).catchError((_) {}),
      itemBuilder: (report) => Card(
        child: ListTile(
          title: Text(
            report.note.isEmpty ? 'Báo cáo không có ghi chú' : report.note,
          ),
          subtitle: Text('${report.actorName} → ${report.targetName}'),
          trailing: PopupMenuButton<String>(
            enabled: !controller.isMutating(report.id),
            onSelected: (value) =>
                controller.resolve(report, value).catchError((_) {}),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'resolved',
                child: Text('Đánh dấu đã xử lý'),
              ),
              PopupMenuItem(value: 'dismissed', child: Text('Bỏ qua')),
              PopupMenuItem(value: 'open', child: Text('Mở lại')),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PaymentsSection extends StatelessWidget {
  const _PaymentsSection({required this.controller});
  final AdminManagementController controller;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: 'Thanh toán',
    controller: controller,
    onSearch: (q) => controller.loadPayments(search: q).catchError((_) {}),
    child: _PagedList(
      page: controller.paymentPage,
      empty: 'Không có thanh toán',
      onPage: (p) => controller.loadPayments(page: p).catchError((_) {}),
      itemBuilder: (payment) => Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text('${payment.amount.round()} ${payment.currency}'),
          subtitle: Text(
            '${payment.userName} • ${payment.planId} • #${payment.orderCode}',
          ),
          trailing: Chip(label: Text(payment.status)),
        ),
      ),
    ),
  );
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({required this.data});
  final Map<String, dynamic>? data;
  @override
  Widget build(BuildContext context) {
    final value = data;
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final summary = value['summary'] is Map
        ? (value['summary'] as Map).cast<String, dynamic>()
        : value;
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final entry in summary.entries.take(8))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(label: Text('${entry.key}: ${entry.value}')),
            ),
        ],
      ),
    );
  }
}

class _UserDetailDialog extends StatelessWidget {
  const _UserDetailDialog({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final user = data['user'] is Map
        ? (data['user'] as Map).cast<String, dynamic>()
        : data;
    final title = user['displayName']?.toString() ?? 'Chi tiết người dùng';
    final stats = user['stats'] is Map ? user['stats'] as Map : const {};
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final key in [
              'email',
              'phone',
              'bio',
              'isPremium',
              'createdAt',
            ])
              if (user[key] != null)
                ListTile(
                  title: Text(key),
                  subtitle: Text(user[key].toString()),
                ),
            for (final entry in stats.entries)
              ListTile(
                title: Text(entry.key.toString()),
                trailing: Text(entry.value.toString()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _PagedList<T> extends StatelessWidget {
  const _PagedList({
    required this.page,
    required this.empty,
    required this.itemBuilder,
    required this.onPage,
  });
  final AdminPage<T>? page;
  final String empty;
  final Widget Function(T) itemBuilder;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) {
    final value = page;
    if (value == null) {
      return const Center(child: Text('Chọn mục để tải dữ liệu'));
    }
    if (value.items.isEmpty) return Center(child: Text(empty));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        for (final item in value.items) itemBuilder(item),
        if (value.pages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value.page > 1 ? () => onPage(value.page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${value.page}/${value.pages} • ${value.total}'),
              IconButton(
                onPressed: value.page < value.pages
                    ? () => onPage(value.page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.controller,
    required this.destination,
  });
  final AdminAnalyticsController controller;
  final int destination;
  @override
  Widget build(BuildContext context) {
    final analytics = controller.analytics;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  switch (destination) {
                    2 => 'KPI vận hành',
                    6 => 'Báo cáo điều hành bằng AI',
                    _ => 'Analytics 24 giờ',
                  },
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (destination != 6)
                DropdownButton<String>(
                  value: controller.metric,
                  items: const [
                    DropdownMenuItem(value: 'events', child: Text('Sự kiện')),
                    DropdownMenuItem(
                      value: 'activeUsers',
                      child: Text('Active users'),
                    ),
                    DropdownMenuItem(
                      value: 'interactions',
                      child: Text('Tương tác'),
                    ),
                    DropdownMenuItem(value: 'aiMeal', child: Text('AI món ăn')),
                  ],
                  onChanged: controller.loading
                      ? null
                      : (value) {
                          if (value != null) {
                            controller
                                .load(selectedMetric: value)
                                .catchError((_) {});
                          }
                        },
                ),
            ],
          ),
        ),
        if (controller.loading) const LinearProgressIndicator(),
        if (controller.errorMessage case final message?)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (analytics != null && destination != 6) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in analytics.summary.entries.take(6))
                      Chip(label: Text('${entry.key}: ${entry.value}')),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hoạt động theo giờ',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: _HourlyBars(points: analytics.hourly),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (destination == 1)
                if (controller.heatmap case final heatmap?)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Heatmap ${heatmap.metric}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _HeatmapGrid(cells: heatmap.cells),
                        ],
                      ),
                    ),
                  ),
              if (destination == 6) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Báo cáo điều hành bằng AI',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: controller.generating
                                  ? null
                                  : () => controller.generate().catchError(
                                      (_) {},
                                    ),
                              icon: controller.generating
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: const Text('Tạo báo cáo'),
                            ),
                          ],
                        ),
                        if (controller.report case final report?) ...[
                          const SizedBox(height: 12),
                          Text(
                            report.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          for (final line in report.executiveSummary)
                            ListTile(
                              leading: const Icon(Icons.insights),
                              title: Text(line),
                            ),
                          for (final section in report.sections)
                            _AiReportSection(section: section),
                          if (report.priorityActions.isNotEmpty)
                            const Text(
                              'Hành động ưu tiên',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          for (final action in report.priorityActions)
                            ListTile(
                              leading: const Icon(Icons.check_circle_outline),
                              title: Text(action),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AiReportSection extends StatelessWidget {
  const _AiReportSection({required this.section});
  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final title =
        section['title']?.toString() ??
        section['heading']?.toString() ??
        'Phân tích';
    final summary = section['summary']?.toString();
    final metrics = section['metrics'] is Map
        ? (section['metrics'] as Map).cast<Object?, Object?>()
        : const <Object?, Object?>{};
    final items = <String>[
      for (final key in ['findings', 'recommendations', 'actions'])
        if (section[key] is List)
          ...(section[key] as List).map((item) => item.toString()),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(summary),
          ],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in metrics.entries)
                  Chip(label: Text('${entry.key}: ${entry.value}')),
              ],
            ),
          ],
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HourlyBars extends StatelessWidget {
  const _HourlyBars({required this.points});
  final List<AdminHourlyPoint> points;
  @override
  Widget build(BuildContext context) {
    final maxValue = points.isEmpty
        ? 1
        : math.max(1, points.map((e) => e.events).reduce(math.max));
    return Semantics(
      label: 'Biểu đồ sự kiện theo 24 giờ',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Tooltip(
                message: '${point.label}: ${point.events}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FractionallySizedBox(
                    heightFactor: point.events / maxValue,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.cells});
  final List<AdminHeatmapCell> cells;
  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const Text('Chưa có dữ liệu heatmap');
    final maxValue = math.max(1, cells.map((e) => e.value).reduce(math.max));
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final cell in cells)
          Tooltip(
            message: '${cell.day} ${cell.hour}:00 — ${cell.value}',
            child: Semantics(
              label: '${cell.weekday} ${cell.hour} giờ: ${cell.value}',
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: .12 + .88 * cell.value / maxValue,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
