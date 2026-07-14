#!/usr/bin/env bash
# Packages the Linux release bundle into a .deb.
# Usage: tool/build_deb.sh <version> <dist-dir>
# Expects `flutter build linux --release` to have run already (the Makefile
# `deb` target takes care of that).
set -euo pipefail

VERSION="${1:?usage: build_deb.sh <version> <dist-dir>}"
DIST="${2:?usage: build_deb.sh <version> <dist-dir>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="$REPO_ROOT/build/linux/x64/release/bundle"
PKG="dayforge"          # installed package / menu identity
BIN="advanced_todo"     # Flutter's compiled executable name (unchanged)
ICON_SRC="$REPO_ROOT/assets/icon/dayforge.png"
ARCH="amd64"
STAGING="$REPO_ROOT/build/deb/${PKG}_${VERSION}_${ARCH}"

if [[ ! -x "$BUNDLE/$BIN" ]]; then
  echo "error: $BUNDLE/$BIN not found — run 'flutter build linux --release' first" >&2
  exit 1
fi

rm -rf "$STAGING"
mkdir -p "$STAGING/DEBIAN" \
         "$STAGING/opt/$PKG" \
         "$STAGING/usr/bin" \
         "$STAGING/usr/share/applications" \
         "$STAGING/usr/share/icons/hicolor/512x512/apps"

cp -r "$BUNDLE/." "$STAGING/opt/$PKG/"
cp "$ICON_SRC" "$STAGING/usr/share/icons/hicolor/512x512/apps/$PKG.png"

# Wrapper instead of a symlink: the binary resolves its data/ and lib/
# directories relative to the executable path.
cat > "$STAGING/usr/bin/$PKG" <<EOF
#!/bin/sh
exec /opt/$PKG/$BIN "\$@"
EOF
chmod 755 "$STAGING/usr/bin/$PKG"

cat > "$STAGING/usr/share/applications/$PKG.desktop" <<EOF
[Desktop Entry]
Name=DayForge
Comment=Forge daily habits — recurring tasks with streaks, reminders and cloud sync
Exec=/usr/bin/$PKG
Icon=$PKG
Terminal=false
Type=Application
Categories=Utility;Office;
EOF

INSTALLED_SIZE=$(du -sk "$STAGING" | cut -f1)
cat > "$STAGING/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Installed-Size: $INSTALLED_SIZE
Depends: libgtk-3-0, libstdc++6
Maintainer: ItzzInfinity <prasadanjan25@gmail.com>
Description: DayForge — recurring daily task tracker
 Forge daily habits: track recurring daily tasks with per-day remarks,
 streaks, progress calendars, reminders and Firebase cloud sync.
EOF

mkdir -p "$DIST"
dpkg-deb --build --root-owner-group "$STAGING" \
  "$DIST/${PKG}_${VERSION}_${ARCH}.deb"
echo "deb: built $DIST/${PKG}_${VERSION}_${ARCH}.deb"
