#!/usr/bin/env bash
# Regenerates docs/screenshots/*.png from the running app.
#
#   tool/screenshots/capture.sh            all scenes
#   tool/screenshots/capture.sh 03-progress 07-today-dark   just these
#
# One scene per `flutter test` process, and each process is killed as soon as
# its PNG lands. That is not paranoia: rasterising a widget tree writes a
# perfectly good file and then leaves the test runner wedged — it never
# reports the test complete and sits until it times out. It happens with a
# hand-rolled RenderRepaintBoundary.toImage *and* with matchesGoldenFile, and
# it happens on a trivial one-Text tree, so it is the headless runner in this
# environment rather than anything about DayForge. The file is the artefact we
# want; the runner's exit code is noise.
set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1
OUT=docs/screenshots
LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

STILLS=(01-today 02-tasks 03-progress 04-task-detail 05-add-task 06-settings
        07-today-dark 08-sign-in)
# tick stops at 02 on purpose: the third tick reaches the 5-of-9 majority,
# which completes the day and folds the card into the collapsed "Completed
# today" section — so there is no +1 button left to press for a frame 03.
FILMS=(film-tick-00 film-tick-01 film-tick-02
       film-tabs-00 film-tabs-01 film-tabs-02 film-tabs-03)
ALL=("${STILLS[@]}" "${FILMS[@]}")
scenes=("$@")
[[ ${#scenes[@]} -eq 0 ]] && scenes=("${ALL[@]}")

# `film-tick-02` writes docs/screenshots/film/tick-02.png; everything else
# writes docs/screenshots/<scene>.png.
png_for() {
  case "$1" in
    film-*) echo "$OUT/film/${1#film-}.png" ;;
    *)      echo "$OUT/$1.png" ;;
  esac
}

mkdir -p "$OUT"
fails=0

for scene in "${scenes[@]}"; do
  png=$(png_for "$scene")
  rm -f "$png"
  mkdir -p "$OUT/film"
  printf '%-16s ' "$scene"

  # setsid so the whole process group can be killed — `flutter` is a shell
  # wrapper and killing it alone leaves the dart VM running.
  setsid flutter test --update-goldens --plain-name "$scene" \
      tool/screenshots/capture_test.dart >"$LOG" 2>&1 &
  pid=$!

  for _ in $(seq 1 240); do          # up to 120s
    [[ -s "$png" ]] && break
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.5
  done
  sleep 1                            # let the write flush
  kill -- -"$pid" 2>/dev/null
  wait "$pid" 2>/dev/null

  if [[ -s "$png" ]]; then
    echo "ok  ($(du -h "$png" | cut -f1))"
  else
    echo "FAILED"
    tail -25 "$LOG" | sed 's/^/    /'
    fails=$((fails + 1))
  fi
done

echo
if [[ $fails -gt 0 ]]; then
  echo "$fails scene(s) failed."
  exit 1
fi
echo "All scenes written to $OUT/."
