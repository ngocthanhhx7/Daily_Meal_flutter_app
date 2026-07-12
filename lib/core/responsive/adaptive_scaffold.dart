import 'package:daily_meal_flutter_app/core/responsive/app_breakpoints.dart';
import 'package:flutter/material.dart';

class AdaptiveDestination {
  const AdaptiveDestination({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.dailyMealStyle = false,
    super.key,
  });

  static const compactNavigationKey = Key('adaptive-compact-navigation');
  static const railNavigationKey = Key('adaptive-rail-navigation');
  static const expandedNavigationKey = Key('adaptive-expanded-navigation');
  static const contentKey = Key('adaptive-content');

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final bool dailyMealStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = AppBreakpoints.windowClassFor(constraints.maxWidth);
        if (windowClass == AppWindowClass.compact) {
          return Scaffold(
            body: body,
            bottomNavigationBar: dailyMealStyle
                ? null
                : NavigationBar(
                    key: compactNavigationKey,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    destinations: [
                      for (final destination in destinations)
                        NavigationDestination(
                          icon: Icon(destination.icon),
                          label: destination.label,
                        ),
                    ],
                  ),
          );
        }

        final expanded = windowClass == AppWindowClass.expanded;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                key: expanded ? expandedNavigationKey : railNavigationKey,
                extended: expanded,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    key: contentKey,
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SizedBox.expand(child: body),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
