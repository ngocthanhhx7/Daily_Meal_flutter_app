import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/premium/data/premium_api.dart';
import 'package:daily_meal_flutter_app/features/premium/domain/premium_models.dart';

abstract interface class PremiumRepositoryContract {
  Future<List<PremiumPlan>> plans();
  Future<PayosPayment> createPayment(PremiumPlanId planId);
  Future<PayosPayment> payment(int orderCode);
  Future<AppUser> claimTrial();
}

class PremiumRepository implements PremiumRepositoryContract {
  PremiumRepository(this._api);
  final PremiumApi _api;
  @override
  Future<List<PremiumPlan>> plans() => _api.plans();
  @override
  Future<PayosPayment> createPayment(PremiumPlanId planId) =>
      _api.createPayment(planId);
  @override
  Future<PayosPayment> payment(int orderCode) => _api.payment(orderCode);
  @override
  Future<AppUser> claimTrial() => _api.claimTrial();
}
