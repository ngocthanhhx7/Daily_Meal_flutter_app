import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/premium/application/premium_controller.dart';
import 'package:daily_meal_flutter_app/features/premium/data/premium_repository.dart';
import 'package:daily_meal_flutter_app/features/premium/domain/premium_models.dart';
import 'package:daily_meal_flutter_app/features/premium/presentation/premium_screen.dart';
import 'package:daily_meal_flutter_app/features/premium/services/checkout_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final appUser = AppUser.fromJson({
  'id': 'u1',
  'displayName': 'User',
  'isPremium': false,
  'premiumTrialUsed': false,
  'preferences': {'completedOnboarding': true},
  'counts': {},
});
PayosPayment makePayment(PaymentStatus status) => PayosPayment(
  id: 'p1',
  planId: PremiumPlanId.quarter,
  orderCode: 123,
  amount: 99000,
  currency: 'VND',
  status: status,
  checkoutUrl: 'https://pay.payos.vn/web/p1',
);

class _Repository implements PremiumRepositoryContract {
  @override
  Future<List<PremiumPlan>> plans() async => const [
    PremiumPlan(
      id: PremiumPlanId.month,
      name: 'Gói tháng',
      displayPrice: '39k/tháng',
      amount: 39000,
      durationMonths: 1,
    ),
    PremiumPlan(
      id: PremiumPlanId.quarter,
      name: 'Gói 3 tháng',
      displayPrice: '99k/3 tháng',
      amount: 99000,
      durationMonths: 3,
    ),
  ];
  @override
  Future<PayosPayment> createPayment(PremiumPlanId planId) async =>
      makePayment(PaymentStatus.pending);
  @override
  Future<PayosPayment> payment(int orderCode) async =>
      makePayment(PaymentStatus.paid);
  @override
  Future<AppUser> claimTrial() async => appUser;
}

class _Launcher implements CheckoutLauncher {
  Uri? uri;
  @override
  Future<bool> open(Uri uri) async {
    this.uri = uri;
    return true;
  }
}

void main() {
  testWidgets('selects plan, launches PayOS and renders payment status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final launcher = _Launcher();
    final controller = PremiumController(_Repository(), launcher);
    await controller.load();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PremiumScreen(controller: controller, user: appUser),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Gói 3 tháng'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Gói 3 tháng'), findsOneWidget);
    await tester.tap(find.text('Gói tháng'));
    await tester.tap(find.byKey(const Key('premium-checkout')));
    await tester.pumpAndSettle();
    expect(launcher.uri?.host, 'pay.payos.vn');
    expect(find.textContaining('PENDING'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Kiểm tra trạng thái'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kiểm tra trạng thái'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PAID'), findsOneWidget);
  });
}
