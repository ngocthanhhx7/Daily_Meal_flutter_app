import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/premium/application/premium_controller.dart';
import 'package:daily_meal_flutter_app/features/premium/application/premium_providers.dart';
import 'package:daily_meal_flutter_app/features/premium/domain/premium_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({this.controller, this.user, super.key});
  final PremiumController? controller;
  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PremiumController value =
        controller ?? ref.watch(premiumControllerProvider);
    final currentUser = user ?? ref.watch(authControllerProvider).state.user;
    final content = _content(context, value, currentUser);
    return Scaffold(
      body: controller == null
          ? content
          : AnimatedBuilder(
              animation: value,
              builder: (_, _) => _content(context, value, currentUser),
            ),
    );
  }

  Widget _content(
    BuildContext context,
    PremiumController controller,
    AppUser? user,
  ) {
    return DailyMealBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'Quay lại',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.chevron_left, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Quyền lợi Premium',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    children: [
                      Card(
                        color: AppColors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.diamond_rounded,
                                size: 32,
                                color: AppColors.yellow,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Daily Premium',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Nâng tầm phong cách nấu ăn và chia sẻ của bạn lên đỉnh cao.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _Benefit(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Mở khóa nhãn dán 3D độc quyền',
                        description:
                            'Bộ sticker đặc biệt chỉ dành cho thành viên Premium.',
                      ),
                      const _Benefit(
                        icon: Icons.analytics_outlined,
                        title: 'Phân tích dinh dưỡng AI nâng cao',
                        description:
                            'Calo, protein, carbs, fat và cảnh báo chi tiết.',
                      ),
                      const _Benefit(
                        icon: Icons.people_outline,
                        title: 'Nhóm gia đình chia sẻ',
                        description:
                            'Dùng chung quyền lợi Premium với tối đa 5 thành viên mà không phát sinh thêm phí.',
                      ),
                      if (user?.isPremium == true) ...[
                        const SizedBox(height: 18),
                        const Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.verified_rounded,
                              color: AppColors.greenDark,
                            ),
                            title: Text('Premium đang hoạt động'),
                            subtitle: Text(
                              'Toàn bộ quyền lợi đã được kích hoạt trên tài khoản.',
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        Text(
                          'Chọn gói phù hợp',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (controller.loading && controller.plans.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else if (controller.errorMessage != null &&
                            controller.plans.isEmpty)
                          OutlinedButton(
                            onPressed: () =>
                                controller.load().catchError((_) {}),
                            child: const Text('Tải lại danh sách gói'),
                          )
                        else
                          for (final plan in controller.plans)
                            _PlanTile(
                              plan: plan,
                              selected: plan.id == controller.selectedPlan,
                              onTap: () => controller.selectPlan(plan.id),
                            ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const Key('premium-checkout'),
                          onPressed:
                              controller.checkoutBusy ||
                                  controller.plans.isEmpty
                              ? null
                              : () => _checkout(context, controller),
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          label: Text(
                            controller.checkoutBusy
                                ? 'Đang xử lý...'
                                : 'Thanh toán bằng PayOS',
                          ),
                        ),
                        if (controller.activePayment case final payment?) ...[
                          const SizedBox(height: 12),
                          _PaymentCard(
                            payment: payment,
                            busy: controller.checkoutBusy,
                            onRefresh: () =>
                                controller.refreshPayment().catchError((_) {}),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkout(
    BuildContext context,
    PremiumController controller,
  ) async {
    try {
      await controller.checkout();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở thanh toán PayOS.')),
        );
      }
    }
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: icon == Icons.auto_awesome_rounded
                ? AppColors.yellow
                : AppColors.greenDark,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });
  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: selected
        ? AppColors.yellow.withValues(alpha: .05)
        : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? AppColors.yellow : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: ListTile(
      onTap: onTap,
      title: Text(plan.name),
      subtitle: Text('${plan.durationMonths} tháng'),
      trailing: Text(
        plan.displayPrice,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.busy,
    required this.onRefresh,
  });
  final PayosPayment payment;
  final bool busy;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        payment.status == PaymentStatus.paid
            ? Icons.check_circle
            : Icons.schedule,
        color: payment.status == PaymentStatus.paid
            ? AppColors.greenDark
            : null,
      ),
      title: Text('Đơn #${payment.orderCode} • ${payment.status.wireValue}'),
      subtitle: Text('${payment.amount} ${payment.currency}'),
      trailing: payment.terminal
          ? null
          : IconButton(
              tooltip: 'Kiểm tra trạng thái',
              onPressed: busy ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
    ),
  );
}
