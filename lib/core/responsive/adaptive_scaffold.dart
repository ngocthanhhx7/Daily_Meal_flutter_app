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
                ? _DailyMealBottomNavigation(
                    key: compactNavigationKey,
                    destinations: destinations,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                  )
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

class _DailyMealBottomNavigation extends StatelessWidget {
  const _DailyMealBottomNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final middle = <int>[
      0,
      2,
      3,
    ].where((index) => index < destinations.length).toList(growable: false);
    return Material(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 8, 34, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PlainDestinationButton(
                destination: destinations[1],
                selected: selectedIndex == 1,
                onPressed: () => onDestinationSelected(1),
              ),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final index in middle)
                      IconButton(
                        tooltip: destinations[index].label,
                        onPressed: () => onDestinationSelected(index),
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        color: selectedIndex == index
                            ? const Color(0xFFF6DE68)
                            : Colors.white,
                        icon: Icon(destinations[index].icon),
                      ),
                  ],
                ),
              ),
              _PlainDestinationButton(
                destination: destinations[4],
                selected: selectedIndex == 4,
                onPressed: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlainDestinationButton extends StatelessWidget {
  const _PlainDestinationButton({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final AdaptiveDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: destination.label,
      onPressed: onPressed,
      iconSize: 22,
      color: selected ? const Color(0xFF4F6F3D) : const Color(0xFF0D0D0D),
      icon: Icon(destination.icon),
    );
  }
}
