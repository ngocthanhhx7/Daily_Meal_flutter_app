import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AdminDestination {
  const AdminDestination({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.onRefresh,
    required this.onLogout,
    super.key,
  });

  static const desktopBreakpoint = 992.0;
  static const compactHeaderBreakpoint = 760.0;
  static const compactNavigationKey = Key('admin-compact-navigation');
  static const desktopNavigationKey = Key('admin-desktop-navigation');

  final List<AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= desktopBreakpoint) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Row(
            children: [
              SizedBox(
                width: 250,
                child: _DesktopSidebar(
                  key: desktopNavigationKey,
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelected: onDestinationSelected,
                  onRefresh: onRefresh,
                  onLogout: onLogout,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopBar(
                      title: destinations[selectedIndex].label,
                      onRefresh: onRefresh,
                      onLogout: onLogout,
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              _AdminTopBar(
                title: 'Daily Meal Admin',
                onRefresh: onRefresh,
                onLogout: onLogout,
                compact: constraints.maxWidth < compactHeaderBreakpoint,
              ),
              SizedBox(
                key: compactNavigationKey,
                height: 52,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < destinations.length;
                        index++
                      ) ...[
                        Builder(
                          builder: (context) {
                            final selected = selectedIndex == index;
                            return ChoiceChip(
                              selected: selected,
                              onSelected: (_) => onDestinationSelected(index),
                              avatar: Icon(
                                destinations[index].icon,
                                size: 17,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.ink,
                              ),
                              label: Text(destinations[index].label),
                              labelStyle: TextStyle(
                                color: selected
                                    ? AppColors.white
                                    : AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                              selectedColor: AppColors.greenDark,
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.line),
                            );
                          },
                        ),
                        if (index != destinations.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: body),
            ],
          ),
        ),
      );
    },
  );
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRefresh,
    required this.onLogout,
    super.key,
  });

  final List<AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF191B1F),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/logo/logo-square.png'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Daily Meal',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'DASHBOARD',
                style: TextStyle(
                  color: Color(0xFF8B8E94),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (var index = 0; index < destinations.length; index++) ...[
              if (index == destinations.length - 1)
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 8),
                  child: Text(
                    'HỆ THỐNG',
                    style: TextStyle(
                      color: Color(0xFF8B8E94),
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              _SidebarItem(
                destination: destinations[index],
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
              const SizedBox(height: 4),
            ],
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: Color(0xFF3B3E44)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm mới'),
            ),
            TextButton.icon(
              onPressed: onLogout,
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });
  final AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.greenDark : Colors.transparent,
    borderRadius: BorderRadius.circular(9),
    child: ListTile(
      dense: true,
      minLeadingWidth: 22,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      onTap: onTap,
      leading: Icon(
        destination.icon,
        size: 19,
        color: selected ? AppColors.white : const Color(0xFFB8BBC1),
      ),
      title: Text(
        destination.label,
        style: TextStyle(
          color: selected ? AppColors.white : const Color(0xFFD7D9DD),
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.onRefresh,
    required this.onLogout,
    this.compact = false,
  });
  final String title;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: SizedBox(
      height: compact ? 58 : 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Làm mới dữ liệu',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Đăng xuất Admin',
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
      ),
    ),
  );
}
