/// Which build of DayForge is running.
///
/// The Makefile passes these in (`--dart-define`, `--build-name`), so every
/// release artifact can be identified from inside the app — Settings → About
/// shows them. A build started straight from `flutter run` has no stamp and
/// reports itself as a dev build, which is exactly what it is.
class BuildInfo {
  const BuildInfo._();

  /// Marketing version, e.g. `1.0.0`.
  static const version =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// Commit count + short sha (+ `.dirty<timestamp>` when built from an
  /// edited tree), e.g. `13.70eab8c` — set by `make apk` / `make deb`.
  static const buildId =
      String.fromEnvironment('BUILD_ID', defaultValue: 'dev');

  static bool get isDevBuild => buildId == 'dev';

  /// Built from uncommitted changes: the exact source is not in git.
  static bool get isDirty => buildId.contains('.dirty');

  /// `DayForge 1.0.0 (build 13.70eab8c)`.
  static String get label => isDevBuild
      ? 'DayForge $version (dev build)'
      : 'DayForge $version (build $buildId)';
}
