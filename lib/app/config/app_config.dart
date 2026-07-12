import 'package:daily_meal_flutter_app/app/config/config_exception.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.facebookAppId,
    required this.googleWebClientId,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromMap(const {
      'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
      'FACEBOOK_APP_ID': String.fromEnvironment('FACEBOOK_APP_ID'),
      'GOOGLE_WEB_CLIENT_ID': String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    });
  }

  factory AppConfig.fromMap(Map<String, String> values) {
    final apiBaseUrl = _parseApiBaseUrl(values['API_BASE_URL'] ?? '');

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      facebookAppId: values['FACEBOOK_APP_ID']?.trim() ?? '',
      googleWebClientId: values['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '',
    );
  }

  final Uri apiBaseUrl;
  final String facebookAppId;
  final String googleWebClientId;

  static Uri _parseApiBaseUrl(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw const ConfigException('API_BASE_URL', 'API base URL is required.');
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ConfigException(
        'API_BASE_URL',
        'API base URL must be an absolute URL.',
      );
    }

    final isLocalDevelopmentHost =
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '10.0.2.2';
    if (uri.scheme != 'https' &&
        !(uri.scheme == 'http' && isLocalDevelopmentHost)) {
      throw const ConfigException(
        'API_BASE_URL',
        'HTTPS is required outside local development.',
      );
    }

    final normalizedPath = uri.path == '/'
        ? ''
        : uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: normalizedPath);
  }
}
