import 'package:daily_meal_flutter_app/app/router/app_router.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:daily_meal_flutter_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DailyMealApp extends StatefulWidget {
  const DailyMealApp({super.key});

  @override
  State<DailyMealApp> createState() => _DailyMealAppState();
}

class _DailyMealAppState extends State<DailyMealApp> {
  late final ValueNotifier<SessionRouteState> _sessionState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _sessionState = ValueNotifier(SessionRouteState.signedOut);
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
