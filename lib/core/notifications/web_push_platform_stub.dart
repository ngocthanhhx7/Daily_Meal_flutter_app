abstract interface class WebPushPlatform {
  bool get supported;
  String readiness(String publicKey);
  Future<Map<String, dynamic>> subscribe(String publicKey);
  String? registeredEndpoint();
  void clearEndpoint();
}

class BrowserWebPushPlatform implements WebPushPlatform {
  @override
  bool get supported => false;
  @override
  String readiness(String publicKey) => 'unsupported';
  @override
  Future<Map<String, dynamic>> subscribe(String publicKey) =>
      throw UnsupportedError('Web Push is only available in browsers');
  @override
  String? registeredEndpoint() => null;
  @override
  void clearEndpoint() {}
}
