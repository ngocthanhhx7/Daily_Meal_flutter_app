import 'package:daily_meal_flutter_app/core/analytics/analytics_event.dart';

class AnalyticsSanitizer {
  static const _allowedKeys = {
    'screen',
    'referrer',
    'durationMs',
    'status',
    'method',
    'path',
    'httpStatus',
    'contentType',
    'context',
    'platform',
  };

  static final _unsafeName = RegExp(
    r'(password|otp|token|authorization|message)',
    caseSensitive: false,
  );
  static final _validName = RegExp(r'^[a-z][a-z0-9_]{1,63}$');

  AnalyticsEvent sanitize(AnalyticsEvent event) {
    if (!_validName.hasMatch(event.name) || _unsafeName.hasMatch(event.name)) {
      throw ArgumentError.value(event.name, 'event.name', 'Unsafe event name');
    }

    return AnalyticsEvent(
      name: event.name,
      properties: _sanitizeMap(event.properties),
    );
  }

  Map<String, Object?> _sanitizeMap(Map<String, Object?> input) {
    final output = <String, Object?>{};
    for (final entry in input.entries) {
      if (!_allowedKeys.contains(entry.key)) {
        continue;
      }
      final value = entry.value;
      if (value is Map) {
        final nested = _sanitizeMap(value.cast<String, Object?>());
        if (nested.isNotEmpty) {
          output[entry.key] = nested;
        }
      } else if (value == null ||
          value is String ||
          value is num ||
          value is bool) {
        output[entry.key] = value;
      }
    }
    return output;
  }
}
