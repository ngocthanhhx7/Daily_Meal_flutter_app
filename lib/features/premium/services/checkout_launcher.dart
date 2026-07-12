import 'package:url_launcher/url_launcher.dart';

abstract interface class CheckoutLauncher {
  Future<bool> open(Uri uri);
}

class UrlCheckoutLauncher implements CheckoutLauncher {
  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
