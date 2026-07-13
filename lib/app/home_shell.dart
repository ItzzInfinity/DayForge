import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/daily/presentation/today_screen.dart';
import '../features/onboarding/presentation/tutorial_overlay.dart';
import '../features/onboarding/providers.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';

/// Signed-in navigation shell: bottom bar on narrow layouts (mobile),
/// navigation rail on wide ones (desktop). The FSD requires the daily
/// workflow to be a few taps, so Today is the first tab.
///
/// Also hosts the first-run tutorial: a spotlight circles each section
/// (the rest of the screen blacked out) and NEXT walks through them.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  /// Rail-vs-bottom-bar breakpoint (logical pixels).
  static const wideBreakpoint = 640.0;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  /// Current tutorial stop; null = tour not running.
  int? _tutorialStep;
  bool _tutorialStarted = false;

  /// One key per destination, shared by its icon and selectedIcon (only
  /// one of the two is ever inflated) so the tutorial can find each tab.
  final _navKeys = List.generate(4, (_) => GlobalKey());

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

  late final _tutorialSteps = [
    TutorialStep(
      title: 'Today — your daily checklist',
      body: 'Tick each task off here every day, with an optional note about '
          'how it went. Finish everything and you get a little celebration.',
      targetKey: _navKeys[0],
    ),
    TutorialStep(
      title: 'Tasks — add and manage',
      body: 'Tap + to add a task: how many days it runs, its category and '
          'reminder time. Search, filter and archive from here too.',
      targetKey: _navKeys[1],
    ),
    TutorialStep(
      title: 'Progress — watch it grow',
      body: 'Streaks, completion bars and an activity grid that glows '
          'brighter the more you tick.',
      targetKey: _navKeys[2],
    ),
    TutorialStep(
      title: 'Settings — make it yours',
      body: 'Reminders, snooze, theme, data export — and under Advanced you '
          'can backfill days you did before adding a task.',
      targetKey: _navKeys[3],
    ),
  ];

  void _select(int index) => setState(() => _index = index);

  void _finishTutorial() {
    setState(() => _tutorialStep = null);
    // Fire-and-forget: worst case the tour shows once more next launch.
    ref.read(tutorialStoreProvider).markSeen().then(
          (_) => ref.invalidate(tutorialSeenProvider),
          onError: (_) {},
        );
  }

  void _nextTutorialStep() {
    final step = _tutorialStep;
    if (step == null) return;
    if (step >= _tutorialSteps.length - 1) {
      _finishTutorial();
      return;
    }
    // Switch to the spotlighted tab so the user sees what's described.
    setState(() {
      _tutorialStep = step + 1;
      _index = step + 1;
    });
  }

  Widget _keyedIcon(int index, IconData icon) =>
      KeyedSubtree(key: _navKeys[index], child: Icon(icon));

  @override
  Widget build(BuildContext context) {
    // First run on this device → start the tour once the shell has laid
    // out (the spotlight measures the nav icons' positions).
    final seen = ref.watch(tutorialSeenProvider).value;
    if (seen == false && !_tutorialStarted) {
      _tutorialStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tutorialStep = 0);
      });
    }

    final wide =
        MediaQuery.sizeOf(context).width >= HomeShell.wideBreakpoint;
    final body = IndexedStack(index: _index, children: _screens);

    final Widget shell;
    if (wide) {
      shell = Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (i, d) in _destinations.indexed)
                  NavigationRailDestination(
                    icon: _keyedIcon(i, d.icon),
                    selectedIcon: _keyedIcon(i, d.selected),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    } else {
      shell = Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (final (i, d) in _destinations.indexed)
              NavigationDestination(
                icon: _keyedIcon(i, d.icon),
                selectedIcon: _keyedIcon(i, d.selected),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final step = _tutorialStep;
    if (step == null) return shell;
    return Stack(
      children: [
        shell,
        TutorialOverlay(
          step: _tutorialSteps[step],
          stepIndex: step,
          stepCount: _tutorialSteps.length,
          onNext: _nextTutorialStep,
          onSkip: _finishTutorial,
        ),
      ],
    );
  }
}
