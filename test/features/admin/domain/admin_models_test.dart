import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses dashboard KPI analytics without using the 24h contract', () {
    final dashboard = AdminDashboard.fromJson({
      'rangePreset': '7d',
      'analytics': {
        'activeUsers': {'dau': 12, 'wau': 44, 'mau': 90, 'returning': 8},
        'sessions': {'averageDurationMs': 42000, 'bounceRate': .18},
        'feed': {'ctr': .32, 'averageScrollDepth': 67},
        'technical': {
          'averageApiResponseMs': 128,
          'averageImageLoadMs': 310,
          'runtimeErrors': 2,
          'crashRate': .01,
        },
        'creatorConversion': {'rate': .4},
        'postCreation': {'completionRate': .7},
        'mealAnalysis': {'completionRate': .8},
        'premiumFunnel': {'paymentCompletionRate': .25},
      },
    });

    expect(dashboard.analytics.dau, 12);
    expect(dashboard.analytics.averageSessionDurationMs, 42000);
    expect(dashboard.analytics.feedCtr, .32);
    expect(dashboard.analytics.averageApiResponseMs, 128);
    expect(dashboard.analytics.paymentCompletionRate, .25);
  });
}
