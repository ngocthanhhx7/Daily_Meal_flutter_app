class ConfigException implements Exception {
  const ConfigException(this.key, this.message);

  final String key;
  final String message;

  @override
  String toString() => 'ConfigException($key): $message';
}
