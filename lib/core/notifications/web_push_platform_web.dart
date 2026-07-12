import 'dart:convert';
import 'dart:js_interop';

abstract interface class WebPushPlatform {
  bool get supported;
  String readiness(String publicKey);
  Future<Map<String, dynamic>> subscribe(String publicKey);
  String? registeredEndpoint();
  void clearEndpoint();
}

@JS('dailyMealPush.readiness')
external JSString _readiness(JSString publicKey);
@JS('dailyMealPush.subscribe')
external JSPromise<JSString> _subscribe(JSString publicKey);
@JS('dailyMealPush.endpoint')
external JSString _endpoint();
@JS('dailyMealPush.clearEndpoint')
external void _clearEndpoint();

class BrowserWebPushPlatform implements WebPushPlatform {
  @override
  bool get supported => true;
  @override
  String readiness(String publicKey) => _readiness(publicKey.toJS).toDart;
  @override
  Future<Map<String, dynamic>> subscribe(String publicKey) async =>
      (jsonDecode((await _subscribe(publicKey.toJS).toDart).toDart) as Map)
          .cast<String, dynamic>();
  @override
  String? registeredEndpoint() {
    final value = _endpoint().toDart.trim();
    return value.isEmpty ? null : value;
  }

  @override
  void clearEndpoint() => _clearEndpoint();
}
