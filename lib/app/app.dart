import 'dart:async';

import 'package:daily_meal_flutter_app/app/router/app_router.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:daily_meal_flutter_app/app/theme/app_theme.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DailyMealApp extends ConsumerStatefulWidget {
  const DailyMealApp({super.key});

  @override
  ConsumerState<DailyMealApp> createState() => _DailyMealAppState();
}

class _DailyMealAppState extends ConsumerState<DailyMealApp> {
  late final ValueNotifier<SessionRouteState> _sessionState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _sessionState = ValueNotifier(SessionRouteState.loading);
    _router = createAppRouter(_sessionState);
  }

  @override
  void dispose() {
    _router.dispose();
    _sessionState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(authControllerProvider).state.routeState;
    if (_sessionState.value != routeState) {
      scheduleMicrotask(() {
        if (mounted) _sessionState.value = routeState;
      });
    }

    return Semantics(
      label: 'Daily Meal application',
      container: true,
      child: MaterialApp.router(
        title: 'Daily Meal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
