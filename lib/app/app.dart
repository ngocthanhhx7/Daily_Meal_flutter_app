import 'dart:async';

import 'package:daily_meal_flutter_app/app/router/app_router.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:daily_meal_flutter_app/app/theme/app_theme.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/core/analytics/analytics_providers.dart';
import 'package:daily_meal_flutter_app/core/analytics/analytics_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DailyMealApp extends ConsumerStatefulWidget {
  const DailyMealApp({super.key});

  @override
  ConsumerState<DailyMealApp> createState() => _DailyMealAppState();
}

class _DailyMealAppState extends ConsumerState<DailyMealApp>
    with WidgetsBindingObserver {
  late final ValueNotifier<SessionRouteState> _sessionState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _sessionState = ValueNotifier(SessionRouteState.loading);
    _router = createAppRouter(_sessionState);
    WidgetsBinding.instance.addObserver(this);
    final analytics = ref.read(analyticsClientProvider);
    analytics.track(const AnalyticsEvent(name: 'app_open'));
    unawaited(analytics.flush().catchError((_) {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    _sessionState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final analytics = ref.read(analyticsClientProvider);
      analytics.track(
        AnalyticsEvent(
          name: 'app_background',
          properties: {'status': state.name},
        ),
      );
      unawaited(analytics.flush().catchError((_) {}));
    }
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
