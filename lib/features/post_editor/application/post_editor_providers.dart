import 'dart:async';

import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_controller.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_api.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:daily_meal_flutter_app/features/post_editor/services/media_picker_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final postEditorRepositoryProvider = Provider<PostEditorRepositoryContract>((
  ref,
) {
  return PostEditorRepository(PostEditorApi(ref.watch(dioProvider)));
});

final postManagementRepositoryProvider =
    Provider<PostManagementRepositoryContract>((ref) {
      return PostManagementRepository(PostEditorApi(ref.watch(dioProvider)));
    });

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return PluginMediaPickerService();
});

final postEditorControllerProvider =
    ChangeNotifierProvider.autoDispose<PostEditorController>((ref) {
      final premium =
          ref.watch(authControllerProvider).state.user?.isPremium ?? false;
      final controller = PostEditorController(
        ref.watch(postEditorRepositoryProvider),
        isPremium: premium,
      );
      unawaited(controller.loadStickers());
      return controller;
    });
