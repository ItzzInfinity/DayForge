import 'package:flutter/material.dart';

/// One stop of the first-run tour: a section to spotlight and what to say
/// about it. [targetKey] must sit on a widget that is on screen when the
/// step shows (the home shell keys its navigation icons).
class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    required this.targetKey,
  });

  final String title;
  final String body;
  final GlobalKey targetKey;
}

/// Full-screen first-run tutorial: blacks out the app except a circle
/// around the current step's target, explains the section, and a NEXT
/// button walks through the remaining steps.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.stepCount,
    required this.onNext,
    required this.onSkip,
  });

  final TutorialStep step;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  bool get _isLast => stepIndex == stepCount - 1;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // Where's the target? (Falls back to the screen centre if it is not
    // laid out yet — should not happen, but never crash the tour.)
    final box = step.targetKey.currentContext?.findRenderObject();
    final Rect target;
    if (box is RenderBox && box.hasSize) {
      target = box.localToGlobal(Offset.zero) & box.size;
    } else {
      target = Rect.fromCenter(
          center: screen.center(Offset.zero), width: 48, height: 48);
    }
    final radius =
        (target.longestSide / 2 + 28).clamp(40.0, screen.shortestSide / 3);
    final center = target.center;
    // Put the card in whichever half of the screen the circle is not in.
    final cardOnTop = center.dy > screen.height / 2;

    final theme = Theme.of(context);
    return Material(
      key: const Key('tutorial-overlay'),
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Scrim with the spotlight hole; swallows every tap so the tour
          // cannot be dismissed by poking the app underneath.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(center: center, radius: radius),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: cardOnTop ? screen.height * 0.18 : null,
            bottom: cardOnTop ? null : screen.height * 0.18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  step.body,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      key: const Key('tutorial-skip'),
                      onPressed: onSkip,
                      child: const Text('Skip',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    const Spacer(),
                    Text(
                      '${stepIndex + 1} / $stepCount',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white54),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      key: const Key('tutorial-next'),
                      onPressed: onNext,
                      child: Text(_isLast ? 'DONE' : 'NEXT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      hole,
    );
    canvas.drawPath(
        scrim, Paint()..color = Colors.black.withValues(alpha: 0.78));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.center != center || old.radius != radius;
}
