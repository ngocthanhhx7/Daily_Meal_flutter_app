import 'package:daily_meal_flutter_app/core/analytics/analytics_client.dart';
import 'package:daily_meal_flutter_app/core/analytics/dio_analytics_sink.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsClientProvider = Provider<AnalyticsClient>(
  (ref) => AnalyticsClient(sink: DioAnalyticsSink(ref.watch(dioProvider))),
);
