import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('covers all 28 production React Native route identities uniquely', () {
    expect(AppRoute.values, hasLength(28));
    expect(AppRoute.values.map((route) => route.path).toSet(), hasLength(28));
    expect(AppRoute.values.map((route) => route.path).toSet(), {
      '/login',
      '/admin/login',
      '/onboarding',
      '/',
      '/search',
      '/profile',
      '/profile/edit',
      '/profile/saved',
      '/users/:id',
      '/users/:id/follows',
      '/profile/blocked',
      '/messages',
      '/messages/:id',
      '/notifications',
      '/posts/:id/comments',
      '/posts/:id/recipe',
      '/premium',
      '/settings',
      '/settings/password',
      '/posts/summary',
      '/profile/progress',
      '/support',
      '/profile/share',
      '/create',
      '/posts/:id/edit',
      '/admin',
      '/admin/users',
      '/admin/users/:id',
    });
  });
}
