import 'package:flutter/material.dart';

/// Caps content width so lists and forms keep a readable line length on
/// desktop windows; a no-op on phone-width layouts.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  static const maxWidth = 840.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
