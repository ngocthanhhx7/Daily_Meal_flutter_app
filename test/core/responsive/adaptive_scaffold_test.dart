import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAt(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(
      home: AdaptiveScaffold(
        destinations: [
          AdaptiveDestination(icon: Icons.home_outlined, label: 'Trang chủ'),
          AdaptiveDestination(icon: Icons.search, label: 'Tìm kiếm'),
        ],
        selectedIndex: 0,
        onDestinationSelected: _noop,
        body: Text('Nội dung'),
      ),
    ),
  );
}

void _noop(int _) {}

void main() {
  testWidgets('uses bottom navigation on compact widths', (tester) async {
    await pumpAt(tester, 360);
    expect(find.byKey(AdaptiveScaffold.compactNavigationKey), findsOneWidget);
    expect(find.byKey(AdaptiveScaffold.railNavigationKey), findsNothing);
  });

  testWidgets('uses a navigation rail on medium widths', (tester) async {
    await pumpAt(tester, 600);
    expect(find.byKey(AdaptiveScaffold.railNavigationKey), findsOneWidget);
  });

  testWidgets('bounds content and exposes expanded navigation', (tester) async {
    await pumpAt(tester, 1440);
    expect(find.byKey(AdaptiveScaffold.expandedNavigationKey), findsOneWidget);
    final box = tester.getSize(find.byKey(AdaptiveScaffold.contentKey));
    expect(box.width, lessThanOrEqualTo(1200));
  });
}
