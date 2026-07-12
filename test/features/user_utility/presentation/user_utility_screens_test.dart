import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_controller.dart';
import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_repository.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:daily_meal_flutter_app/features/user_utility/presentation/user_utility_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements UserUtilityRepositoryContract {
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
  @override
  Future<PostSummaryPage> postSummary(
    PostSummaryFilter filter, {
    int page = 1,
  }) async => const PostSummaryPage(posts: [], page: 1, hasMore: false);
  @override
  Future<List<SummaryPost>> userPosts(String userId) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('change password exposes validation without calling backend', (
    tester,
  ) async {
    final controller = UserUtilityController(_Repository());
    await tester.pumpWidget(
      MaterialApp(home: ChangePasswordScreen(controller: controller)),
    );
    await tester.enterText(find.byKey(const Key('current-password')), '123456');
    await tester.enterText(find.byKey(const Key('new-password')), '12345678');
    await tester.enterText(
      find.byKey(const Key('confirm-password')),
      '87654321',
    );
    await tester.tap(find.text('Cập nhật mật khẩu'));
    await tester.pump();
    expect(find.textContaining('chưa khớp'), findsOneWidget);
  });

  testWidgets('support preserves honest no-backend feedback behavior', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SupportScreen()));
    await tester.tap(find.text('Gửi phản hồi'));
    await tester.pump();
    expect(find.textContaining('Vui lòng nhập đầy đủ'), findsOneWidget);
  });
}
