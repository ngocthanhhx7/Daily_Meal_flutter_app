import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/premium/application/premium_controller.dart';
import 'package:daily_meal_flutter_app/features/premium/data/premium_repository.dart';
import 'package:daily_meal_flutter_app/features/premium/domain/premium_models.dart';
import 'package:daily_meal_flutter_app/features/premium/services/checkout_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

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
      id: PremiumPlanId.quarter,
      name: 'Quarter',
      displayPrice: '99k',
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
  Future<AppUser> claimTrial() async => AppUser.fromJson({
    'id': 'u1',
    'displayName': 'User',
    'isPremium': true,
    'premiumTrialUsed': true,
    'preferences': {'completedOnboarding': true},
    'counts': {},
  });
}

class _Launcher implements CheckoutLauncher {
  Uri? opened;
  @override
  Future<bool> open(Uri uri) async {
    opened = uri;
    return true;
  }
}

void main() {
  test(
    'creates checkout, launches HTTPS and reaches paid terminal state',
    () async {
      final launcher = _Launcher();
      var refreshed = false;
      final controller = PremiumController(
        _Repository(),
        launcher,
        refreshUser: () async => refreshed = true,
      );
      await controller.load();
      await controller.checkout();
      expect(launcher.opened?.host, 'pay.payos.vn');
      expect(controller.activePayment?.status, PaymentStatus.pending);
      await controller.refreshPayment();
      expect(controller.activePayment?.status, PaymentStatus.paid);
      expect(refreshed, isTrue);
    },
  );

  test('claims trial and publishes updated authenticated user', () async {
    AppUser? updated;
    final controller = PremiumController(
      _Repository(),
      _Launcher(),
      onUserUpdated: (user) => updated = user,
    );
    await controller.claimTrial();
    expect(updated?.isPremium, isTrue);
    expect(updated?.premiumTrialUsed, isTrue);
  });
}
