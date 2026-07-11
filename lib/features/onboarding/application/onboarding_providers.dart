import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/onboarding/application/onboarding_controller.dart';
import 'package:daily_meal_flutter_app/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(dioProvider));
});

final onboardingControllerProvider =
    ChangeNotifierProvider.autoDispose<OnboardingController>((ref) {
      return OnboardingController(
        ref.watch(onboardingRepositoryProvider),
        ref.watch(authControllerProvider),
      );
    });
