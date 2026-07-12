import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes the complete authenticated user envelope', () {
    final user = AppUser.fromJson({
      'id': 'user-1',
      'email': 'meal@example.com',
      'displayName': 'Daily Chef',
      'avatarUrl': '/uploads/avatar.jpg',
      'birthday': {'date': '1998-05-12', 'visibility': 'dayMonth'},
      'isPremium': true,
      'premiumTrialUsed': true,
      'premiumTrialStartedAt': '2026-07-01T00:00:00.000Z',
      'premiumTrialEndsAt': '2026-08-01T00:00:00.000Z',
      'preferences': {
        'interests': ['Thích ăn uống'],
        'eatingStyles': ['Chế độ keto'],
        'completedOnboarding': true,
      },
      'counts': {'posts': 3, 'followers': 4, 'following': 5, 'friends': 2},
    });

    expect(user.id, 'user-1');
    expect(user.email, 'meal@example.com');
    expect(user.phone, isNull);
    expect(user.birthday?.visibility, BirthdayVisibility.dayMonth);
    expect(user.isPremium, isTrue);
    expect(user.preferences.completedOnboarding, isTrue);
    expect(user.counts.friends, 2);
  });

  test('decodes phone users and server defaults without optional fields', () {
    final user = AppUser.fromJson({
      'id': 'phone-user',
      'phone': '+84901234567',
      'displayName': '+84901234567',
      'isPremium': false,
      'preferences': {
        'interests': <String>[],
        'eatingStyles': <String>[],
        'completedOnboarding': false,
      },
    });

    expect(user.email, isNull);
    expect(user.phone, '+84901234567');
    expect(user.counts.posts, 0);
    expect(user.birthday, isNull);
  });

  test('rejects unknown birthday visibility values', () {
    expect(
      () => AppUser.fromJson({
        'id': 'user-1',
        'displayName': 'User',
        'isPremium': false,
        'birthday': {'visibility': 'public'},
        'preferences': {
          'interests': <String>[],
          'eatingStyles': <String>[],
          'completedOnboarding': false,
        },
      }),
      throwsFormatException,
    );
  });
}
