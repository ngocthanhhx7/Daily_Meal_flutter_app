import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_compact_post_preview.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({this.controller, this.mediaResolver, super.key});
  final ProfileController? controller;
  final MediaUrlResolver? mediaResolver;

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  ProfileController? _owned;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null || _owned != null) return;
    final id = ref.read(authControllerProvider).state.user?.id;
    if (id == null) return;
    _owned = ProfileController(
      ref.read(profileRepositoryProvider),
      userId: id,
      isOwner: true,
    );
    _owned!.load().catchError((_) {});
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? _owned;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => _body(
        controller,
        widget.mediaResolver ?? ref.watch(mediaUrlResolverProvider),
      ),
    );
  }

  Widget _body(ProfileController controller, MediaUrlResolver resolver) {
    final state = controller.state;
    return Scaffold(
      body: DailyMealBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: context.pop,
                          customBorder: const CircleBorder(),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.black,
                            child: Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Đã lưu',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Người dùng',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _content(state, controller, resolver)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    ProfileState state,
    ProfileController controller,
    MediaUrlResolver resolver,
  ) {
    if (state.status == ProfileStatus.idle ||
        state.status == ProfileStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ProfileStatus.failure) {
      return Center(
        child: OutlinedButton(
          onPressed: () => controller.load().catchError((_) {}),
          child: const Text('Thử lại'),
        ),
      );
    }
    if (state.savedPosts.isEmpty) return const _SavedEmpty();
    final left = <FeedPost>[], right = <FeedPost>[];
    for (var i = 0; i < state.savedPosts.length; i++) {
      (i.isEven ? left : right).add(state.savedPosts[i]);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _column(left, resolver)),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: _column(right, resolver),
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(List<FeedPost> posts, MediaUrlResolver resolver) => Column(
    children: [
      for (final post in posts) ...[
        DailyCompactPostPreview(
          post: post,
          resolver: resolver,
          onOpen: () => context.goNamed(
            AppRoute.home.name,
            queryParameters: {'postId': post.id},
          ),
        ),
        const SizedBox(height: 24),
      ],
    ],
  );
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_outline, size: 64, color: AppColors.muted),
          SizedBox(height: 14),
          Text(
            'Chưa lưu bài viết nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14),
          Text(
            'Bấm nút lưu ở các bài đăng thú vị để xem lại công thức và món ăn tại đây bất cứ lúc nào.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}
