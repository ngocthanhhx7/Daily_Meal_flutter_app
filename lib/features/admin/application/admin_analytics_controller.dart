import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter/foundation.dart';

class AdminAnalyticsController extends ChangeNotifier {
  AdminAnalyticsController(this._repository);
  final AdminRepositoryContract _repository;
  AdminRange range = AdminRange.sevenDays;
  String metric = 'events';
  Map<String, dynamic>? summary;
  AdminAnalytics24h? analytics;
  AdminHeatmap? heatmap;
  AdminAiReport? report;
  bool loading = false, generating = false;
  String? errorMessage;

  Future<void> load({String? selectedMetric}) async {
    if (selectedMetric != null) metric = selectedMetric;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.analyticsSummary(range),
        _repository.analytics24h(),
        _repository.heatmap(metric: metric),
      ]);
      summary = values[0] as Map<String, dynamic>;
      analytics = values[1] as AdminAnalytics24h;
      heatmap = values[2] as AdminHeatmap;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> generate({AdminRange? selectedRange}) async {
    if (selectedRange != null) range = selectedRange;
    generating = true;
    errorMessage = null;
    notifyListeners();
    try {
      report = await _repository.generateAiReport(range);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      generating = false;
      notifyListeners();
    }
  }
}
