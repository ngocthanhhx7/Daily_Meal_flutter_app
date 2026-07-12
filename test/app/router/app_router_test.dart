import 'package:daily_meal_flutter_app/app/router/app_router.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('imperative route pushes are reflected in the Web URL', () {
    GoRouter.optionURLReflectsImperativeAPIs = false;
    final session = ValueNotifier(SessionRouteState.user);
    final router = createAppRouter(session);
    addTearDown(() {
      router.dispose();
      session.dispose();
      GoRouter.optionURLReflectsImperativeAPIs = false;
    });

    expect(GoRouter.optionURLReflectsImperativeAPIs, isTrue);
  });
}
