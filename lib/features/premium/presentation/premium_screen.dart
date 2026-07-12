import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
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
    final PremiumController value = controller ?? ref.watch(premiumControllerProvider);
    final currentUser = user ?? ref.watch(authControllerProvider).state.user;
    final content = _content(context, value, currentUser);
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền lợi Premium')),
      body: controller == null
          ? content
          : AnimatedBuilder(animation: value, builder: (_, _) => _content(context, value, currentUser)),
    );
  }

  Widget _content(BuildContext context, PremiumController controller, AppUser? user) {
    return ColoredBox(
      color: AppColors.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: AppColors.greenDark,
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.workspace_premium_rounded, size: 48, color: AppColors.yellow),
                    SizedBox(height: 8),
                    Text('Daily Premium', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('Mở khóa trải nghiệm sáng tạo và dinh dưỡng nâng cao.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              const _Benefit(icon: Icons.auto_awesome_rounded, title: 'Sticker 3D và sticker tùy chỉnh', description: 'Tạo dấu ấn riêng cho mỗi món ăn.'),
              const _Benefit(icon: Icons.analytics_outlined, title: 'Phân tích dinh dưỡng AI nâng cao', description: 'Calo, protein, carbs, fat và cảnh báo chi tiết.'),
              const _Benefit(icon: Icons.video_camera_back_outlined, title: 'Bài viết video', description: 'Đăng video món ăn tối đa 30 giây.'),
              if (user?.isPremium == true) ...[
                const SizedBox(height: 18),
                const Card(child: ListTile(leading: Icon(Icons.verified_rounded, color: AppColors.greenDark), title: Text('Premium đang hoạt động'), subtitle: Text('Toàn bộ quyền lợi đã được kích hoạt trên tài khoản.'))),
              ] else ...[
                if (user != null && !user.premiumTrialUsed) ...[
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.card_giftcard_rounded),
                      title: const Text('Dùng thử Premium miễn phí 30 ngày'),
                      subtitle: const Text('Ưu đãi chỉ được sử dụng một lần.'),
                      trailing: FilledButton.tonal(
                        onPressed: controller.trialBusy ? null : () => _claimTrial(context, controller),
                        child: Text(controller.trialBusy ? 'Đang nhận...' : 'Nhận ngay'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text('Chọn gói phù hợp', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (controller.loading && controller.plans.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (controller.errorMessage != null && controller.plans.isEmpty)
                  OutlinedButton(onPressed: () => controller.load().catchError((_) {}), child: const Text('Tải lại danh sách gói'))
                else
                  for (final plan in controller.plans) _PlanTile(plan: plan, selected: plan.id == controller.selectedPlan, onTap: () => controller.selectPlan(plan.id)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('premium-checkout'),
                  onPressed: controller.checkoutBusy || controller.plans.isEmpty ? null : () => _checkout(context, controller),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(controller.checkoutBusy ? 'Đang xử lý...' : 'Thanh toán bằng PayOS'),
                ),
                if (controller.activePayment case final payment?) ...[
                  const SizedBox(height: 12),
                  _PaymentCard(payment: payment, busy: controller.checkoutBusy, onRefresh: () => controller.refreshPayment().catchError((_) {})),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, PremiumController controller) async {
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
  Future<void> _claimTrial(BuildContext context, PremiumController controller) async {
    try {
      await controller.claimTrial();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kích hoạt Premium miễn phí 30 ngày.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể kích hoạt dùng thử.')),
        );
      }
    }
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.description});
  final IconData icon; final String title; final String description;
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: AppColors.greenDark), title: Text(title), subtitle: Text(description)));
}
class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});
  final PremiumPlan plan; final bool selected; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(
    color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
    child: ListTile(
      onTap: onTap,
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
      title: Text(plan.name),
      subtitle: Text('${plan.displayPrice} • ${plan.durationMonths} tháng'),
      trailing: Text('${plan.amount} ₫'),
    ),
  );
}
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.busy, required this.onRefresh});
  final PayosPayment payment; final bool busy; final VoidCallback onRefresh;
  @override Widget build(BuildContext context) => Card(child: ListTile(
    leading: Icon(payment.status == PaymentStatus.paid ? Icons.check_circle : Icons.schedule, color: payment.status == PaymentStatus.paid ? AppColors.greenDark : null),
    title: Text('Đơn #${payment.orderCode} • ${payment.status.wireValue}'),
    subtitle: Text('${payment.amount} ${payment.currency}'),
    trailing: payment.terminal ? null : IconButton(tooltip: 'Kiểm tra trạng thái', onPressed: busy ? null : onRefresh, icon: const Icon(Icons.refresh)),
  ));
}
