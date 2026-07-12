import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/features/admin/application/admin_providers.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({
    required this.userId,
    this.repository,
    super.key,
  });
  final String userId;
  final AdminRepositoryContract? repository;
  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true, _mutating = false;
  String? _error;
  AdminRepositoryContract get _repository =>
      widget.repository ?? ref.read(adminRepositoryProvider);

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
      final data = await _repository.userDetail(widget.userId);
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải chi tiết người dùng.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _premium(bool value) async {
    final user = _user;
    if (user == null || _mutating) return;
    setState(() => _mutating = true);
    try {
      final updated = await _repository.setPremium(
        user.id,
        value,
        note: 'Cập nhật từ chi tiết Admin',
      );
      if (mounted) {
        setState(() {
          final raw = Map<String, dynamic>.from(_rawUser);
          raw['isPremium'] = updated.isPremium;
          _data = {...?_data, 'user': raw};
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật Premium.')),
        );
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Map<String, dynamic> get _rawUser => _data?['user'] is Map
      ? (_data!['user'] as Map).cast<String, dynamic>()
      : const {};
  AdminUser? get _user =>
      _rawUser.isEmpty ? null : AdminUser.fromJson(_rawUser);
  List<Map<String, dynamic>> _list(String key) {
    final value = _rawUser[key] ?? _data?[key];
    return value is List
        ? value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F6F8),
    appBar: AppBar(
      title: const Text('Chi tiết người dùng'),
      leading: IconButton(
        onPressed: context.pop,
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới',
        ),
      ],
    ),
    body: _loading && _data == null
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _data == null
        ? Center(
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(_error!),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _hero(),
                        const SizedBox(height: 16),
                        _stats(),
                        const SizedBox(height: 16),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _posts()),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _interactions(),
                                    const SizedBox(height: 16),
                                    _audit(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _posts(),
                          const SizedBox(height: 16),
                          _interactions(),
                          const SizedBox(height: 16),
                          _audit(),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
  );

  Widget _hero() {
    final user = _user, raw = _rawUser;
    if (user == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.green,
                  child: Text(
                    user.name.characters.first.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(user.email.isNotEmpty ? user.email : user.phone),
                    if (raw['bio'] != null)
                      SizedBox(
                        width: 360,
                        child: Text(raw['bio'].toString(), maxLines: 2),
                      ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Premium'),
                const SizedBox(width: 8),
                Switch(
                  value: user.isPremium,
                  onChanged: _mutating ? null : _premium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats() {
    final stats = _rawUser['stats'] is Map
        ? _rawUser['stats'] as Map
        : const {};
    final values = [
      ('Bài đăng', stats['posts'] ?? 0, Icons.article_outlined),
      ('Người theo dõi', stats['followers'] ?? 0, Icons.people_outline),
      ('Đang theo dõi', stats['following'] ?? 0, Icons.person_add_outlined),
      ('Báo cáo', stats['reports'] ?? 0, Icons.flag_outlined),
    ];
    return LayoutBuilder(
      builder: (_, constraints) => GridView.count(
        crossAxisCount: constraints.maxWidth >= 700 ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          for (final item in values)
            Card(
              child: ListTile(
                leading: Icon(item.$3, color: AppColors.greenDark),
                title: Text(
                  '${item.$2}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(item.$1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _posts() => _section(
    'Bài đăng gần đây',
    _list('recentPosts'),
    (item) =>
        '${item['caption'] ?? '(Không có caption)'}\n${item['visibility'] ?? ''} · ${item['moderationStatus'] ?? 'visible'}',
  );
  Widget _interactions() => _section(
    'Tương tác cần chú ý',
    _list('interactions'),
    (item) =>
        '${item['type'] ?? 'interaction'} · ${item['status'] ?? ''}\n${item['note'] ?? ''}',
  );
  Widget _audit() => _section(
    'Nhật ký quản trị',
    _list('audit'),
    (item) => '${item['action'] ?? 'action'}\n${item['note'] ?? ''}',
  );

  Widget _section(
    String title,
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic>) label,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Chưa có dữ liệu',
              style: TextStyle(color: AppColors.muted),
            )
          else
            for (final item in items.take(6))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label(item)),
              ),
        ],
      ),
    ),
  );
}
