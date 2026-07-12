import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves the complete production AI report contract', () {
    final report = AdminAiReport.fromJson({
      'generatedAt': '2026-07-12T00:00:00Z',
      'range': {'start': '2026-06-12T00:00:00Z', 'end': '2026-07-12T00:00:00Z'},
      'report': {
        'title': 'Báo cáo vận hành',
        'executiveSummary': ['Tăng trưởng ổn định'],
        'sections': [
          {
            'key': 'technical',
            'title': 'Hiệu suất kỹ thuật',
            'objective': 'Theo dõi độ ổn định',
            'metrics': [
              {
                'name': 'API p95',
                'value': '320 ms',
                'assessment': 'Cần theo dõi',
                'meaning': 'Ảnh hưởng tốc độ feed',
              },
            ],
            'insights': ['Tăng nhẹ so với tuần trước'],
            'conclusion': 'Chưa vượt ngưỡng cảnh báo',
            'actions': ['Tối ưu truy vấn feed'],
          },
        ],
        'anomalies': ['Đột biến lỗi lúc 09:00'],
        'priorityActions': ['Theo dõi API p95'],
        'risks': ['Nguy cơ feed chậm'],
        'metricsSnapshot': {'apiP95': 320},
      },
    });

    expect(report.sections.single.metrics.single.value, '320 ms');
    expect(report.sections.single.insights, ['Tăng nhẹ so với tuần trước']);
    expect(report.sections.single.conclusion, 'Chưa vượt ngưỡng cảnh báo');
    expect(report.sections.single.actions, ['Tối ưu truy vấn feed']);
    expect(report.anomalies, ['Đột biến lỗi lúc 09:00']);
    expect(report.risks, ['Nguy cơ feed chậm']);
    expect(report.range['start'], '2026-06-12T00:00:00Z');
    expect(report.metricsSnapshot['apiP95'], 320);
  });
}
