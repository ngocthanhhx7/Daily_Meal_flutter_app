import 'package:daily_meal_flutter_app/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots the Daily Meal application', (tester) async {
    await tester.pumpWidget(const DailyMealApp());

    expect(find.bySemanticsLabel('Daily Meal application'), findsOneWidget);
  });
}
