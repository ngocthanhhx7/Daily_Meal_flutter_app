import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_controller.dart';
import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_repository.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:daily_meal_flutter_app/features/user_utility/presentation/user_utility_screens.dart';
import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements UserUtilityRepositoryContract {
  PostSummaryFilter? requestedFilter;
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
  @override
  Future<PostSummaryPage> postSummary(
    PostSummaryFilter filter, {
    int page = 1,
  }) async {
    requestedFilter = filter;
    return const PostSummaryPage(
      posts: [
        SummaryPost(
          id: 'p1',
          caption: 'Bữa sáng xanh',
          authorName: 'Bếp Nhà',
          likes: 12,
          comments: 3,
        ),
      ],
      page: 1,
      hasMore: false,
    );
  }

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
    await tester.scrollUntilVisible(
      find.text('Gửi phản hồi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Gửi phản hồi'));
    await tester.pump();
    expect(find.textContaining('Vui lòng nhập đầy đủ'), findsOneWidget);
  });

  testWidgets('post summary renders source segments and staggered card', (
    tester,
  ) async {
    final repository = _Repository();
    final controller = UserUtilityController(repository);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userUtilityControllerProvider.overrideWith((_) => controller),
          mediaUrlResolverProvider.overrideWithValue(
            MediaUrlResolver(Uri.parse('https://api.dailymeal.site')),
          ),
        ],
        child: const MaterialApp(home: PostSummaryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Bữa sáng xanh'), findsOneWidget);
    expect(find.textContaining('♥ 12'), findsOneWidget);
    await tester.tap(find.text('Bạn bè'));
    await tester.pumpAndSettle();
    expect(repository.requestedFilter, PostSummaryFilter.friends);
  });
}
