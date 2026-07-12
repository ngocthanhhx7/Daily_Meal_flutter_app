import 'dart:async';

import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/search/application/search_controller.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_api.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final searchRepositoryProvider = Provider<SearchRepositoryContract>((ref) {
  final dio = ref.watch(dioProvider);
  return SearchRepository(SearchApi(dio), FeedApi(dio));
});

final searchControllerProvider =
    ChangeNotifierProvider.autoDispose<SearchController>((ref) {
      final controller = SearchController(ref.watch(searchRepositoryProvider));
      unawaited(controller.searchNow().catchError((_) {}));
      return controller;
    });
