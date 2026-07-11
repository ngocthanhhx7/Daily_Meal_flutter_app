enum AppWindowClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const compactMax = 600.0;
  static const expandedMin = 1024.0;

  static AppWindowClass windowClassFor(double width) {
    if (width < compactMax) {
      return AppWindowClass.compact;
    }
    if (width < expandedMin) {
      return AppWindowClass.medium;
    }
    return AppWindowClass.expanded;
  }
}
