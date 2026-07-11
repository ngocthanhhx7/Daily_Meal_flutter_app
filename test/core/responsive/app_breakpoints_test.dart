import 'package:daily_meal_flutter_app/core/responsive/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies compact widths below 600', () {
    expect(AppBreakpoints.windowClassFor(0), AppWindowClass.compact);
    expect(AppBreakpoints.windowClassFor(599), AppWindowClass.compact);
  });

  test('classifies medium widths from 600 through 1023', () {
    expect(AppBreakpoints.windowClassFor(600), AppWindowClass.medium);
    expect(AppBreakpoints.windowClassFor(1023), AppWindowClass.medium);
  });

  test('classifies expanded widths from 1024', () {
    expect(AppBreakpoints.windowClassFor(1024), AppWindowClass.expanded);
    expect(AppBreakpoints.windowClassFor(1440), AppWindowClass.expanded);
  });
}
