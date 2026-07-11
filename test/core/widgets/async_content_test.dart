import 'package:daily_meal_flutter_app/core/widgets/async_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpState(
  WidgetTester tester,
  AsyncContentState<String> state, {
  VoidCallback? onRetry,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: AsyncContent<String>(
        state: state,
        onRetry: onRetry,
        dataBuilder: (context, value) => Text(value),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders loading without error content', (tester) async {
    await pumpState(tester, const AsyncContentState.loading());
    expect(find.bySemanticsLabel('Đang tải nội dung'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('renders data and empty states exclusively', (tester) async {
    await pumpState(tester, const AsyncContentState.data('Bữa ăn'));
    expect(find.text('Bữa ăn'), findsOneWidget);

    await pumpState(tester, const AsyncContentState.empty());
    expect(find.bySemanticsLabel('Không có nội dung'), findsOneWidget);
    expect(find.text('Bữa ăn'), findsNothing);
  });

  testWidgets('renders an accessible retry action', (tester) async {
    var retries = 0;
    await pumpState(
      tester,
      const AsyncContentState.error('Không thể tải dữ liệu.'),
      onRetry: () => retries++,
    );

    final button = find.widgetWithText(FilledButton, 'Thử lại');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.tap(button);
    expect(retries, 1);
  });
}
