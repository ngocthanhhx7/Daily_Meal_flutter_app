import 'package:daily_meal_flutter_app/features/profile/application/blocked_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_providers.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedScreen extends ConsumerStatefulWidget {
  const BlockedScreen({this.controller, super.key});
  final BlockedController? controller;
  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> {
  BlockedController? _owned;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null || _owned != null) return;
    _owned = BlockedController(ref.read(profileRepositoryProvider))
      ..load().catchError((_) {});
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
      builder: (_, _) => Scaffold(
        body: DailyMealBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.chevron_left, size: 24),
                        ),
                        const Expanded(
                          child: Text(
                            'Đã chặn',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: controller.loading
                        ? const Center(child: CircularProgressIndicator())
                        : controller.errorMessage != null &&
                              controller.users.isEmpty
                        ? Center(
                            child: OutlinedButton(
                              onPressed: () =>
                                  controller.load().catchError((_) {}),
                              child: const Text('Thử lại'),
                            ),
                          )
                        : controller.users.isEmpty
                        ? const _BlockedEmptyState()
                        : ListView.separated(
                            itemCount: controller.users.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final user = controller.users[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(color: AppColors.line),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.canvasStrong,
                                      child: Text(
                                        user.displayName.characters.first
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.displayName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            user.email ?? 'Không có email',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.yellow,
                                        foregroundColor: AppColors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: controller.isBusy(user.id)
                                          ? null
                                          : () => _confirmUnblock(
                                              context,
                                              controller,
                                              user.id,
                                              user.displayName,
                                            ),
                                      child: const Text('Bỏ chặn'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    BlockedController controller,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bỏ chặn'),
        content: Text('Bạn có chắc muốn bỏ chặn người dùng $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ chặn'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.unblock(id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã bỏ chặn $name.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể bỏ chặn lúc này, vui lòng thử lại.'),
          ),
        );
      }
    }
  }
}

class _BlockedEmptyState extends StatelessWidget {
  const _BlockedEmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.muted),
          SizedBox(height: 14),
          Text(
            'Danh sách trống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14),
          Text(
            'Bạn chưa chặn người dùng nào. Danh sách người dùng bị bạn chặn sẽ hiển thị ở đây!',
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
