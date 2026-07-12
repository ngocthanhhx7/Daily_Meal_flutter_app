import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers production HTTPS App Links for shared user content', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:autoVerify="true"'));
    expect(manifest, contains('android:scheme="https"'));
    expect(manifest, contains('android:host="dailymeal.site"'));
    expect(manifest, contains('android:pathPrefix="/users/"'));
    expect(manifest, contains('android:pathPrefix="/posts/"'));
  });
}
