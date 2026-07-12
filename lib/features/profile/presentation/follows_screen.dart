import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_providers.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

enum FollowTab { followers, following }

class FollowsScreen extends ConsumerStatefulWidget {
  const FollowsScreen({
    required this.userId,
    this.initialTab = FollowTab.followers,
    this.displayName,
    this.currentUserId,
    this.repository,
    this.mediaResolver,
    super.key,
  });
  final String userId;
  final FollowTab initialTab;
  final String? displayName;
  final String? currentUserId;
  final ProfileRepositoryContract? repository;
  final MediaUrlResolver? mediaResolver;
  @override
  ConsumerState<FollowsScreen> createState() => _FollowsScreenState();
}

class _FollowsScreenState extends ConsumerState<FollowsScreen> {
  late FollowTab _tab = widget.initialTab;
  List<PublicUser> _users = const [];
  bool _loading = true;
  String? _error, _busyId;

  ProfileRepositoryContract get _repository =>
      widget.repository ?? ref.read(profileRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _repository.loadFollows(
        widget.userId,
        followers: _tab == FollowTab.followers,
      );
      if (mounted) setState(() => _users = users);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải danh sách người dùng.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(PublicUser user) async {
    if (_busyId != null) return;
    setState(() => _busyId = user.id);
    try {
      final updated = await _repository.setFollowing(
        user.id,
        following: !user.relationship.isFollowing,
      );
      if (mounted) {
        setState(
          () => _users = [
            for (final item in _users)
              if (item.id == user.id) updated else item,
          ],
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật theo dõi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _selectTab(FollowTab value) {
    if (value == _tab) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.replaceNamed(
        AppRoute.follows.name,
        pathParameters: {'id': widget.userId},
        queryParameters: {
          'tab': value == FollowTab.following ? 'following' : 'followers',
          'name': ?widget.displayName,
        },
      );
      return;
    }
    setState(() => _tab = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final ownId =
        widget.currentUserId ?? ref.read(authControllerProvider).state.user?.id;
    final MediaUrlResolver resolver =
        widget.mediaResolver ?? ref.watch(mediaUrlResolverProvider);
    return Scaffold(
      body: DailyMealBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: context.pop,
                          icon: SvgPicture.asset(
                            'assets/icons/White/Arrow_Left_circle.svg',
                            width: 22,
                          ),
                          tooltip: 'Quay lại',
                        ),
                        Expanded(
                          child: Text(
                            widget.userId == ownId
                                ? 'Hồ sơ của tôi'
                                : (widget.displayName ?? 'Danh sách'),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5E8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: const Color(0xFFE8F0DE),
                          child: Icon(
                            _tab == FollowTab.followers
                                ? Icons.people_outline
                                : Icons.person_add_outlined,
                            color: AppColors.greenDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tab == FollowTab.followers
                                    ? 'Cộng đồng đang theo dõi bạn'
                                    : 'Những người bạn đang đồng hành',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${_users.length} ${_tab == FollowTab.followers ? 'người theo dõi' : 'đang theo dõi'}',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FollowSegments(
                      selected: _tab,
                      onSelected: _selectTab,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _body(resolver, ownId)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(MediaUrlResolver resolver, String? ownId) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text(_error!),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _tab == FollowTab.followers
                    ? Icons.people_outline
                    : Icons.person_add_outlined,
                size: 64,
                color: AppColors.muted,
              ),
              const SizedBox(height: 14),
              Text(
                _tab == FollowTab.followers
                    ? 'Chưa có người theo dõi'
                    : 'Chưa theo dõi ai',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _tab == FollowTab.followers
                    ? 'Tương tác và chia sẻ nhiều hơn để mọi người tìm thấy bạn.'
                    : 'Khám phá những người sáng tạo khác tại màn hình Tìm kiếm.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _users[index], avatar = resolver.resolve(user.avatarUrl);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.pushNamed(
                  user.id == ownId
                      ? AppRoute.profile.name
                      : AppRoute.publicProfile.name,
                  pathParameters: user.id == ownId ? const {} : {'id': user.id},
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: avatar == null
                      ? null
                      : NetworkImage(avatar.toString()),
                  child: avatar == null
                      ? Text(user.displayName.characters.first.toUpperCase())
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      user.bio ?? '${user.counts.followers} người theo dõi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (user.id != ownId)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: user.relationship.isFollowing
                        ? AppColors.surface
                        : AppColors.yellow,
                    foregroundColor: AppColors.black,
                    side: BorderSide(
                      color: user.relationship.isFollowing
                          ? AppColors.line
                          : AppColors.yellow,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _busyId == user.id ? null : () => _toggle(user),
                  child: Text(
                    user.relationship.isFriend
                        ? 'Bạn bè'
                        : user.relationship.isFollowing
                        ? 'Đang theo dõi'
                        : user.relationship.followsMe
                        ? 'Theo dõi lại'
                        : 'Theo dõi',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FollowSegments extends StatelessWidget {
  const _FollowSegments({required this.selected, required this.onSelected});
  final FollowTab selected;
  final ValueChanged<FollowTab> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEAE0),
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        for (final tab in FollowTab.values)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(tab),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                constraints: const BoxConstraints(minHeight: 38),
                decoration: BoxDecoration(
                  color: selected == tab ? AppColors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tab == FollowTab.followers
                      ? 'Người theo dõi'
                      : 'Đang theo dõi',
                  style: TextStyle(
                    color: selected == tab ? AppColors.white : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
