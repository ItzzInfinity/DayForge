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
PKG="advanced-todo"
ARCH="amd64"
STAGING="$REPO_ROOT/build/deb/${PKG}_${VERSION}_${ARCH}"

if [[ ! -x "$BUNDLE/advanced_todo" ]]; then
  echo "error: $BUNDLE/advanced_todo not found — run 'flutter build linux --release' first" >&2
  exit 1
fi

rm -rf "$STAGING"
mkdir -p "$STAGING/DEBIAN" \
         "$STAGING/opt/$PKG" \
         "$STAGING/usr/bin" \
         "$STAGING/usr/share/applications"

cp -r "$BUNDLE/." "$STAGING/opt/$PKG/"

# Wrapper instead of a symlink: the binary resolves its data/ and lib/
# directories relative to the executable path.
cat > "$STAGING/usr/bin/$PKG" <<'EOF'
#!/bin/sh
exec /opt/advanced-todo/advanced_todo "$@"
EOF
chmod 755 "$STAGING/usr/bin/$PKG"

cat > "$STAGING/usr/share/applications/$PKG.desktop" <<EOF
[Desktop Entry]
Name=Advanced To-Do
Comment=Recurring daily tasks with streaks, reminders and cloud sync
Exec=/usr/bin/$PKG
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
Maintainer: Sisir Radar <anjan@sisirradar.com>
Description: Advanced To-Do — recurring daily task tracker
 Track recurring daily tasks with per-day remarks, streaks, progress
 calendars, reminders and Firebase cloud sync.
EOF

mkdir -p "$DIST"
dpkg-deb --build --root-owner-group "$STAGING" \
  "$DIST/${PKG}_${VERSION}_${ARCH}.deb"
echo "deb: built $DIST/${PKG}_${VERSION}_${ARCH}.deb"
