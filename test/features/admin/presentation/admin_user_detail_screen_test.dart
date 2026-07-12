import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:daily_meal_flutter_app/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements AdminRepositoryContract {
  bool premium = false;
  @override
  Future<Map<String, dynamic>> userDetail(String id) async => {
    'user': {
      'id': id,
      'displayName': 'An Nguyen',
      'email': 'an@example.com',
      'bio': 'Daily creator',
      'isPremium': premium,
      'stats': {'posts': 3, 'followers': 12, 'following': 4, 'reports': 1},
      'recentPosts': [
        {
          'id': 'p1',
          'caption': 'Bữa sáng',
          'visibility': 'public',
          'moderationStatus': 'visible',
        },
      ],
      'interactions': [
        {'id': 'i1', 'type': 'report', 'status': 'open', 'note': 'spam'},
      ],
      'audit': [
        {'id': 'a1', 'action': 'premium.updated', 'note': 'approved'},
      ],
    },
  };
  @override
  Future<AdminUser> setPremium(
    String id,
    bool value, {
    String note = '',
  }) async {
    premium = value;
    return AdminUser(
      id: id,
      name: 'An Nguyen',
      email: 'an@example.com',
      isPremium: value,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('renders responsive admin user workspace and toggles premium', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AdminUserDetailScreen(userId: 'u1', repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('An Nguyen'), findsOneWidget);
    expect(find.text('Bài đăng gần đây'), findsOneWidget);
    expect(find.text('Tương tác cần chú ý'), findsOneWidget);
    expect(find.text('Nhật ký quản trị'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repository.premium, isTrue);
  });
}
