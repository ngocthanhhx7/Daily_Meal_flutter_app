import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/user_utility/application/user_utility_controller.dart';
import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_api.dart';
import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final userUtilityRepositoryProvider = Provider<UserUtilityRepositoryContract>(
  (ref) => UserUtilityRepository(UserUtilityApi(ref.watch(dioProvider))),
);
final userUtilityControllerProvider =
    ChangeNotifierProvider.autoDispose<UserUtilityController>(
      (ref) => UserUtilityController(ref.watch(userUtilityRepositoryProvider)),
    );
