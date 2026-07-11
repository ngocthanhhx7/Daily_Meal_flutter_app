class MediaUrlResolver {
  MediaUrlResolver(Uri apiBaseUrl)
    : _apiBaseUrl = apiBaseUrl.replace(
        path: _trimTrailingSlash(apiBaseUrl.path),
      );

  final Uri _apiBaseUrl;

  Uri? resolve(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    final parsed = Uri.parse(value);
    if (parsed.hasScheme && parsed.host.isNotEmpty) {
      return parsed;
    }

    final relativePath = parsed.path.replaceFirst(RegExp(r'^/+'), '');
    final basePath = _apiBaseUrl.path.replaceFirst(RegExp(r'^/+'), '');
    final path = [if (basePath.isNotEmpty) basePath, relativePath].join('/');

    return _apiBaseUrl.replace(
      path: '/$path',
      query: parsed.hasQuery ? parsed.query : null,
      fragment: parsed.hasFragment ? parsed.fragment : null,
    );
  }

  static String _trimTrailingSlash(String path) =>
      path.replaceFirst(RegExp(r'/+$'), '');
}
