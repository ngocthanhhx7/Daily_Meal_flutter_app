import 'dart:async';

import 'package:daily_meal_flutter_app/features/auth/services/social_identity_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coalesces concurrent and repeated SDK initialization', () async {
    final initializer = SocialSdkInitializer();
    final gate = Completer<void>();
    var calls = 0;

    Future<void> initialize() async {
      calls += 1;
      await gate.future;
    }

    final first = initializer.run(initialize);
    final second = initializer.run(initialize);
    expect(calls, 1);

    gate.complete();
    await Future.wait([first, second]);
    await initializer.run(initialize);
    expect(calls, 1);
  });

  test('allows retry after an SDK initialization failure', () async {
    final initializer = SocialSdkInitializer();
    var calls = 0;

    Future<void> initialize() async {
      calls += 1;
      if (calls == 1) throw StateError('temporary failure');
    }

    await expectLater(initializer.run(initialize), throwsStateError);
    await initializer.run(initialize);
    expect(calls, 2);
  });
}
