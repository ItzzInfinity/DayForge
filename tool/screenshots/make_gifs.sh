#!/usr/bin/env bash
# Assembles the frame sequences captured by capture.sh into the README's GIFs.
#
#   tool/screenshots/capture.sh film-tick film-tabs   # frames
#   tool/screenshots/make_gifs.sh                     # -> docs/screenshots/*.gif
#
# Frames come out at 1000px wide, which is far more than a README needs and
# would make a multi-megabyte GIF. They are scaled to GIF_WIDTH and quantised;
# the last frame of each film holds longer so the loop has a readable beat.
set -euo pipefail

cd "$(dirname "$0")/../.." || exit 1
OUT=docs/screenshots
GIF_WIDTH=${GIF_WIDTH:-320}
DELAY=${DELAY:-90}        # hundredths of a second between frames
HOLD=${HOLD:-220}         # …and on the final frame

command -v convert >/dev/null || { echo "error: ImageMagick not installed" >&2; exit 1; }

build() {
  local name=$1 prefix=$2
  local frames=("$OUT/film/$prefix"-*.png)
  if [[ ! -e "${frames[0]}" ]]; then
    echo "skip $name — no frames (run: tool/screenshots/capture.sh film-$prefix)"
    return
  fi
  local last=${frames[-1]}
  local rest=("${frames[@]:0:${#frames[@]}-1}")

  convert -loop 0 \
      -delay "$DELAY" "${rest[@]}" \
      -delay "$HOLD" "$last" \
      -resize "${GIF_WIDTH}x" \
      -dither FloydSteinberg -colors 128 \
      -layers Optimize \
      "$OUT/$name.gif"
  echo "$name.gif  ${#frames[@]} frames, $(du -h "$OUT/$name.gif" | cut -f1)"
}

build ticking tick
build tabs tabs
