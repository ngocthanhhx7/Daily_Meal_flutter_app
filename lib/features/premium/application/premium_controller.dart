import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/premium/data/premium_repository.dart';
import 'package:daily_meal_flutter_app/features/premium/domain/premium_models.dart';
import 'package:daily_meal_flutter_app/features/premium/services/checkout_launcher.dart';
import 'package:flutter/foundation.dart';

class PremiumController extends ChangeNotifier {
  PremiumController(
    this._repository,
    this._launcher, {
    this.onUserUpdated,
    this.refreshUser,
  });
  final PremiumRepositoryContract _repository;
  final CheckoutLauncher _launcher;
  final ValueChanged<AppUser>? onUserUpdated;
  final Future<void> Function()? refreshUser;
  List<PremiumPlan> plans = const [];
  PremiumPlanId selectedPlan = PremiumPlanId.quarter;
  PayosPayment? activePayment;
  bool loading = false;
  bool checkoutBusy = false;
  bool trialBusy = false;
  String? errorMessage;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      plans = await _repository.plans();
      if (plans.isNotEmpty && !plans.any((plan) => plan.id == selectedPlan)) {
        selectedPlan = plans.first.id;
      }
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectPlan(PremiumPlanId value) {
    selectedPlan = value;
    notifyListeners();
  }

  Future<void> checkout() async {
    if (checkoutBusy) {
      return;
    }
    checkoutBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final payment = await _repository.createPayment(selectedPlan);
      activePayment = payment;
      final uri = Uri.tryParse(payment.checkoutUrl ?? '');
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('PayOS checkout URL is invalid');
      }
      if (!await _launcher.open(uri)) {
        throw StateError('Could not open PayOS checkout');
      }
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      checkoutBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshPayment() async {
    final current = activePayment;
    if (current == null) {
      return;
    }
    checkoutBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      activePayment = await _repository.payment(current.orderCode);
      if (activePayment?.status == PaymentStatus.paid) {
        await refreshUser?.call();
      }
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      checkoutBusy = false;
      notifyListeners();
    }
  }

  Future<void> claimTrial() async {
    if (trialBusy) {
      return;
    }
    trialBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      onUserUpdated?.call(await _repository.claimTrial());
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      trialBusy = false;
      notifyListeners();
    }
  }
}
