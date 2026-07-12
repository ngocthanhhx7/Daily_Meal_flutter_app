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

  test('preserves the complete Analytics 24h response contract', () {
    final analytics = AdminAnalytics24h.fromJson({
      'range': {'preset': 'last24h', 'timezone': 'Asia/Ho_Chi_Minh'},
      'summary': {'activeUsers': 10},
      'hourly': [
        {'hour': 9, 'likes': 4, 'saves': 3, 'comments': 2, 'paymentFailed': 1},
      ],
      'interactionBreakdown': [
        {'type': 'likes', 'count': 4},
      ],
      'aiFunnel': {'usersUsedAi': 5, 'conversionRate': .2},
      'sourceTraffic': [
        {'source': 'home', 'events': 20, 'users': 8},
      ],
      'paymentMetrics': {'success': 2, 'failed': 1},
      'reportMetrics': {'opened': 3, 'pending': 2},
      'tables': {
        'topActions': [
          {'name': 'feed_open', 'count': 12},
        ],
      },
    });

    expect(analytics.range['timezone'], 'Asia/Ho_Chi_Minh');
    expect(analytics.hourly.single.likes, 4);
    expect(analytics.interactionBreakdown.single['type'], 'likes');
    expect(analytics.aiFunnel['usersUsedAi'], 5);
    expect(analytics.sourceTraffic.single['events'], 20);
    expect((analytics.tables['topActions'] as List).single['count'], 12);
  });
}
