import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_controller.dart';
import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_repository.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements UserUtilityRepositoryContract {
  final passwordBodies = <List<String>>[];
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => passwordBodies.add([currentPassword, newPassword]);
  @override
  Future<PostSummaryPage> postSummary(
    PostSummaryFilter filter, {
    int page = 1,
  }) async => PostSummaryPage(
    posts: [
      SummaryPost(
        id: page == 1 ? 'p1' : 'p2',
        caption: filter.label,
        authorName: 'An',
        likes: 2,
        comments: 1,
      ),
    ],
    page: page,
    hasMore: page == 1,
  );
  @override
  Future<List<SummaryPost>> userPosts(String userId) async => const [
    SummaryPost(
      id: 'mine',
      caption: 'Món của tôi',
      authorName: 'Tôi',
      likes: 4,
      comments: 3,
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('validates and submits password using exact values', () async {
    final repository = _Repository();
    final controller = UserUtilityController(repository);
    expect(
      await controller.changePassword('123456', '12345678', 'different'),
      isFalse,
    );
    expect(controller.errorMessage, contains('chưa khớp'));
    expect(
      await controller.changePassword(
        'oldpass',
        'new-pass-123',
        'new-pass-123',
      ),
      isTrue,
    );
    expect(repository.passwordBodies, [
      ['oldpass', 'new-pass-123'],
    ]);
  });

  test(
    'loads filters, deduplicated paging and progress totals source',
    () async {
      final controller = UserUtilityController(_Repository());
      await controller.loadSummary(selected: PostSummaryFilter.friends);
      await controller.loadMore();
      await controller.loadProgress('u1');
      expect(controller.posts.map((e) => e.id), ['p1', 'p2']);
      expect(controller.progressPosts.single.likes, 4);
    },
  );
}
