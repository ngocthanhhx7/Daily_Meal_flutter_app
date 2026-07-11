import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_api.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepositoryContract>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(ProfileApi(dio), SearchApi(dio));
});
