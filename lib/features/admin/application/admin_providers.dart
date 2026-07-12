import 'package:daily_meal_flutter_app/features/admin/application/admin_dashboard_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_management_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_analytics_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_api.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final adminRepositoryProvider = Provider<AdminRepositoryContract>(
  (ref) => AdminRepository(AdminApi(ref.watch(dioProvider))),
);

final adminDashboardControllerProvider =
    ChangeNotifierProvider.autoDispose<AdminDashboardController>((ref) {
      final controller = AdminDashboardController(
        ref.watch(adminRepositoryProvider),
      );
      controller.load().catchError((_) {});
      return controller;
    });

final adminManagementControllerProvider =
    ChangeNotifierProvider.autoDispose<AdminManagementController>(
      (ref) => AdminManagementController(ref.watch(adminRepositoryProvider)),
    );

final adminAnalyticsControllerProvider =
    ChangeNotifierProvider.autoDispose<AdminAnalyticsController>(
      (ref) => AdminAnalyticsController(ref.watch(adminRepositoryProvider)),
    );
