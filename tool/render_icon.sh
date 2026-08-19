#!/usr/bin/env bash
# Renders the vector icon master to the PNGs the toolchains want.
#
#   tool/render_icon.sh            re-render assets/icon/dayforge.png only
#   tool/render_icon.sh --install  …and regenerate the Android mipmaps and
#                                  the Windows .ico via flutter_launcher_icons
#
# assets/icon/dayforge.svg is the master. assets/icon/dayforge.png is a build
# product committed to the repo, because flutter_launcher_icons and the .deb
# packaging both take a raster and neither can read SVG. Edit the SVG and run
# this; never touch the PNG by hand.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$REPO_ROOT/assets/icon/dayforge.svg"
PNG="$REPO_ROOT/assets/icon/dayforge.png"
SIZE=1024

[[ -f "$SVG" ]] || { echo "error: $SVG not found" >&2; exit 1; }

# Two renderers, either is fine. Deliberately not ImageMagick's `convert`:
# without a librsvg delegate it falls back to its own SVG parser, which
# renders the gradients as visible bands.
if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -w "$SIZE" -h "$SIZE" -o "$PNG" "$SVG"
  echo "rendered $PNG (${SIZE}px, rsvg-convert)"
elif python3 -c 'import cairosvg' >/dev/null 2>&1; then
  python3 - "$SVG" "$PNG" "$SIZE" <<'PY'
import sys
import cairosvg
svg, png, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
cairosvg.svg2png(url=svg, write_to=png, output_width=size, output_height=size)
print(f"rendered {png} ({size}px, cairosvg)")
PY
else
  cat >&2 <<'MSG'
error: no SVG renderer found. Install either:
    sudo apt-get install librsvg2-bin     # provides rsvg-convert
    pip3 install --user cairosvg
MSG
  exit 1
fi

if [[ "${1:-}" == "--install" ]]; then
  echo "regenerating launcher icons…"
  (cd "$REPO_ROOT" && dart run flutter_launcher_icons)
  echo "done — Android mipmaps and the Windows .ico now match the SVG."
  echo "The Linux .desktop icon is taken from the PNG by tool/build_deb.sh."
fi
