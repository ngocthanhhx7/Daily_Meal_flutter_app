import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/premium/application/premium_controller.dart';
import 'package:daily_meal_flutter_app/features/premium/data/premium_api.dart';
import 'package:daily_meal_flutter_app/features/premium/data/premium_repository.dart';
import 'package:daily_meal_flutter_app/features/premium/services/checkout_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final premiumRepositoryProvider = Provider<PremiumRepositoryContract>(
  (ref) => PremiumRepository(PremiumApi(ref.watch(dioProvider))),
);
final premiumControllerProvider =
    ChangeNotifierProvider.autoDispose<PremiumController>((ref) {
      final controller = PremiumController(
        ref.watch(premiumRepositoryProvider),
        UrlCheckoutLauncher(),
        onUserUpdated: ref.read(authControllerProvider).updateUser,
        refreshUser: () async {
          ref
              .read(authControllerProvider)
              .updateUser(await ref.read(authRepositoryProvider).currentUser());
        },
      );
      controller.load().catchError((_) {});
      return controller;
    });
