import 'package:daily_meal_flutter_app/features/profile/application/blocked_controller.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_providers.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Tài khoản đã chặn',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        body: DailyMealBackground(
          child: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : controller.errorMessage != null && controller.users.isEmpty
              ? Center(
                  child: OutlinedButton(
                    onPressed: () => controller.load().catchError((_) {}),
                    child: const Text('Thử lại'),
                  ),
                )
              : controller.users.isEmpty
              ? const Center(child: Text('Bạn chưa chặn tài khoản nào.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.users.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final user = controller.users[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(user.displayName),
                      trailing: OutlinedButton(
                        onPressed: controller.isBusy(user.id)
                            ? null
                            : () => controller
                                  .unblock(user.id)
                                  .catchError((_) {}),
                        child: const Text('Bỏ chặn'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
