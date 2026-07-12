import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthRepository implements AuthRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('hydrates the complete edit-profile form from the current user', (
    tester,
  ) async {
    final auth = AuthController(_AuthRepository())
      ..updateUser(
        const AppUser(
          id: 'u1',
          displayName: 'Daily Chef',
          bio: 'Món ngon mỗi ngày',
          birthday: UserBirthday(
            date: '2003-12-31',
            visibility: BirthdayVisibility.dayMonth,
          ),
          themeColor: '#F5B8B5',
          isPremium: false,
          preferences: UserPreferences(
            interests: ['Thích ăn uống'],
            eatingStyles: ['Chế độ keto'],
            completedOnboarding: true,
          ),
          counts: UserCounts(),
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
          mediaUrlResolverProvider.overrideWithValue(
            MediaUrlResolver(Uri.parse('https://api.dailymeal.site')),
          ),
        ],
        child: const MaterialApp(home: EditProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa cá nhân'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Daily Chef'), findsOneWidget);
    expect(find.text('Chọn Avatar mẫu dễ thương'), findsOneWidget);
    expect(find.text('Mèo Noodle'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hiển thị ngày sinh'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hiển thị ngày sinh'), findsOneWidget);
    expect(find.byType(SegmentedButton<BirthdayVisibility>), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Sở thích tìm kiếm'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sở thích tìm kiếm'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Lưu hồ sơ'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lưu hồ sơ'), findsOneWidget);
  });
}
