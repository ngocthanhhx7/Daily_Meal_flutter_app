import 'dart:async';

import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/comments/application/comments_controller.dart';
import 'package:daily_meal_flutter_app/features/comments/data/comments_api.dart';
import 'package:daily_meal_flutter_app/features/comments/data/comments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/messaging_providers.dart';

final commentsRepositoryProvider = Provider<CommentsRepositoryContract>((ref) {
  return CommentsRepository(CommentsApi(ref.watch(dioProvider)));
});

final commentsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<CommentsController, String>((ref, postId) {
      final controller = CommentsController(
        postId,
        ref.watch(commentsRepositoryProvider),
        ref.watch(realtimeClientProvider),
      );
      unawaited(controller.load().catchError((_) {}));
      return controller;
    });
