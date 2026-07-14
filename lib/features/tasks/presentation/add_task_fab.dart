import 'package:flutter/material.dart';

import 'add_task_screen.dart';

/// The + button that opens the add-task form. Shared by every tab except
/// Settings. All tabs live in one IndexedStack, so each FAB needs its own
/// [heroTag] or route transitions would find duplicate heroes.
class AddTaskFab extends StatelessWidget {
  const AddTaskFab({super.key, required this.heroTag});

  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: 'Add task',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AddTaskScreen()),
      ),
      child: const Icon(Icons.add),
    );
  }
}
