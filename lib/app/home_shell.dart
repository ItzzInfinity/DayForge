import 'package:flutter/material.dart';

import '../features/daily/presentation/today_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';

/// Signed-in navigation shell: bottom bar on narrow layouts (mobile),
/// navigation rail on wide ones (desktop). The FSD requires the daily
/// workflow to be a few taps, so Today is the first tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// Rail-vs-bottom-bar breakpoint (logical pixels).
  static const wideBreakpoint = 640.0;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.today_outlined, selected: Icons.today, label: 'Today'),
    (icon: Icons.checklist_outlined, selected: Icons.checklist, label: 'Tasks'),
    (
      icon: Icons.insights_outlined,
      selected: Icons.insights,
      label: 'Progress'
    ),
    (
      icon: Icons.settings_outlined,
      selected: Icons.settings,
      label: 'Settings'
    ),
  ];

  static const _screens = [
    TodayScreen(),
    TasksScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= HomeShell.wideBreakpoint;
    final body = IndexedStack(index: _index, children: _screens);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
