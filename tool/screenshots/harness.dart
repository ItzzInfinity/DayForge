// Shared rig for the README screenshots: real fonts, a phone-shaped surface,
// seeded demo data, and a capture helper.
//
// It lives under tool/ rather than test/ so `flutter test` never runs it —
// it writes files, and that is not something a test suite should do. Run it
// explicitly: see tool/screenshots/README.md.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the PNGs land. Relative to the repo root, which is `flutter test`'s
/// working directory.
const outputDir = 'docs/screenshots';

/// A tall phone, in logical pixels. Captured at [captureScale] so the PNGs
/// are retina-sharp in a README that displays them ~250px wide.
const phoneSize = Size(400, 860);
const captureScale = 2.5;

/// `flutter test` ships a placeholder font that draws every glyph as a filled
/// box — fine for layout assertions, useless for a screenshot. These are real
/// system fonts, registered under the family names the app's theme asks for.
Future<void> loadRealFonts() async {
  Future<void> register(String family, Map<String, FontWeight> files) async {
    final loader = FontLoader(family);
    for (final entry in files.entries) {
      final file = File(entry.key);
      if (!file.existsSync()) continue;
      loader.addFont(
        file.readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
      );
    }
    await loader.load();
  }

  // Built by tool/screenshots/build_font.py: Noto Sans with the handful of
  // glyphs it lacks merged in. Registering a second *font* under the same
  // family does not work — Flutter treats same-family faces as weight
  // variants and the first match wins, with no per-glyph fallback — so the
  // coverage has to be inside one file.
  const built = 'tool/screenshots';
  // Flutter's default families all map to the same faces; the theme names
  // Roboto on Android and a generic sans elsewhere, so cover both.
  for (final family in ['Roboto', 'packages/flutter/Roboto']) {
    await register(family, {
      '$built/DayForgeSans-Regular.ttf': FontWeight.w400,
      '$built/DayForgeSans-Medium.ttf': FontWeight.w500,
      '$built/DayForgeSans-Bold.ttf': FontWeight.w700,
    });
  }

  // Icons come from the Flutter SDK's own cache; the path differs between a
  // snap install and a tarball one, so try both.
  for (final root in [
    '${Platform.environment['HOME']}/snap/flutter/common/flutter',
    '${Platform.environment['HOME']}/development/flutter',
  ]) {
    final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(icons.readAsBytes()
            .then((b) => ByteData.view(Uint8List.fromList(b).buffer)));
      await loader.load();
      break;
    }
  }
}

/// Sizes the test surface to a phone and turns off the "DEBUG" ribbon-style
/// test decorations, so what lands in the PNG is what a user would see.
Future<void> usePhoneSurface(WidgetTester tester) async {
  // flutter_test defaults this to true, which paints every elevation shadow
  // as a hard black shape — that is where the heavy black ring around the +
  // button came from. Real blurred shadows are what a user sees.
  debugDisableShadows = false;
  // Set before the first pump: Material decides on the keyboard-focus ring
  // as it builds, so flipping this inside capture() was too late.
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
  tester.view.physicalSize = phoneSize * captureScale;
  tester.view.devicePixelRatio = captureScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// The app is wrapped in a boundary with this key so there is something with
/// a layer of its own to rasterise — a plain widget tree has none.
const captureKey = ValueKey('screenshot-boundary');

/// Wraps [child] so [capture] can find it.
Widget capturable(Widget child) =>
    RepaintBoundary(key: captureKey, child: child);

/// Advances animations by a fixed number of frames instead of waiting for the
/// scheduler to go idle.
///
/// `pumpAndSettle` is the natural call here and it deadlocks: a blinking text
/// cursor never stops animating, and `toImage` leaves work queued that the
/// next test's settle then waits on forever. A bounded pump reaches the same
/// visual state — nav transitions are ~300ms — and cannot hang.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Writes the whole surface to `docs/screenshots/<name>.png`.
Future<void> capture(WidgetTester tester, String name) async {
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
  await settle(tester);

  final repaint =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
  final image = await repaint.toImage(pixelRatio: captureScale);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$outputDir/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();

  // Replace the tree before the test ends. Today's remark fields keep a
  // cursor blinking forever, and flutter_test's teardown waits for the
  // scheduler to go quiet — so a test that merely *looks* finished hangs
  // until the runner times out. An empty tree has no tickers.
  await tester.pumpWidget(const SizedBox.shrink());
}
