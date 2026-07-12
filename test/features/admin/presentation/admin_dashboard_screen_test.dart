import 'package:daily_meal_flutter_app/features/admin/application/admin_dashboard_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_management_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_analytics_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:daily_meal_flutter_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements AdminRepositoryContract {
  @override
  Future<AdminDashboard> dashboard(AdminRange range) async => AdminDashboard(
    range: range.wireValue,
    allTime: const AdminTotals(users: 120, posts: 80, revenue: 990000),
    inRange: const AdminTotals(users: 7, posts: 11, revenue: 99000),
    today: const AdminToday(users: 2, posts: 3, interactions: 9),
    daily: const [AdminDailyPoint(date: '2026-07-11', interactions: 9)],
    breakdowns: const AdminBreakdowns(
      usersByPremium: [AdminBreakdownItem('premium', 10)],
    ),
    recent: const [],
  );
  @override
  Future<AdminPage<AdminUser>> users({String query = '', int page = 1}) async =>
      const AdminPage(
        items: [
          AdminUser(id: 'u1', name: 'An Nguyen', email: 'an@example.com'),
        ],
        page: 1,
        pages: 1,
        total: 1,
      );
  @override
  Future<Map<String, dynamic>> userInsights(AdminRange range) async => {
    'summary': {'activeUsers': 10},
  };
  @override
  Future<Map<String, dynamic>> userDetail(String id) async => {
    'user': {
      'id': id,
      'displayName': 'An Nguyen',
      'email': 'an@example.com',
      'stats': {'posts': 2},
    },
  };
  @override
  Future<Map<String, dynamic>> analyticsSummary(AdminRange range) async => {
    'summary': {},
  };
  @override
  Future<AdminAnalytics24h> analytics24h() async => const AdminAnalytics24h(
    summary: {'activeUsers': 8},
    hourly: [AdminHourlyPoint(hour: 9, label: '09:00', events: 12)],
  );
  @override
  Future<AdminHeatmap> heatmap({String metric = 'events'}) async =>
      AdminHeatmap(
        metric: metric,
        cells: const [
          AdminHeatmapCell(
            day: '2026-07-12',
            weekday: 'CN',
            hour: 9,
            value: 12,
          ),
        ],
      );
  @override
  Future<AdminAiReport> generateAiReport(AdminRange range) async =>
      const AdminAiReport(
        title: 'Báo cáo AI tuần',
        executiveSummary: ['Tăng trưởng tốt'],
        sections: [],
        priorityActions: ['Theo dõi retention'],
        generatedAt: null,
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  final controller = AdminDashboardController(_Repository());
  await controller.load();
  await tester.pumpWidget(
    MaterialApp(
      home: AdminDashboardScreen(
        controller: controller,
        managementController: AdminManagementController(_Repository()),
        analyticsController: AdminAnalyticsController(_Repository()),
        onLogout: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('uses compact navigation and shows KPI cards', (tester) async {
    await pump(tester, const Size(390, 844));
    expect(find.byKey(AdaptiveScaffold.compactNavigationKey), findsOneWidget);
    expect(find.text('Tổng người dùng'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('Xu hướng tương tác'), findsOneWidget);
  });

  testWidgets('uses expanded navigation on desktop web', (tester) async {
    await pump(tester, const Size(1440, 900));
    expect(find.byKey(AdaptiveScaffold.expandedNavigationKey), findsOneWidget);
    expect(find.text('Daily Meal Admin'), findsOneWidget);
  });

  testWidgets('opens responsive user management from compact navigation', (
    tester,
  ) async {
    await pump(tester, const Size(390, 844));
    await tester.tap(find.text('Người dùng'));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý người dùng'), findsOneWidget);
    expect(find.text('An Nguyen'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('loads analytics heatmap and generates AI report', (
    tester,
  ) async {
    await pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Phân tích'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics 24 giờ'), findsOneWidget);
    expect(find.text('Heatmap events'), findsOneWidget);
    await tester.tap(find.text('Tạo báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo AI tuần'), findsOneWidget);
    expect(find.text('Theo dõi retention'), findsOneWidget);
  });
}
