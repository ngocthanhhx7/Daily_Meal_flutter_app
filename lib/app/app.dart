import 'package:flutter/material.dart';

class DailyMealApp extends StatelessWidget {
  const DailyMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily Meal application',
      container: true,
      child: MaterialApp(
        title: 'Daily Meal',
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
  }
}
