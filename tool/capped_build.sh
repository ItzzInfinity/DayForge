#!/usr/bin/env bash
# Runs a build command under a hard memory ceiling, and keeps the ceiling on
# even when the command escapes into a snap.
#
#   MEM_MAX=8G tool/capped_build.sh flutter build apk --release
#
# Why this is not just `systemd-run --scope`:
#
#   Flutter is installed here as a *classic snap*. `snap run` does not stay in
#   the cgroup it was started in — snapd asks systemd for a fresh transient
#   scope (snap.flutter.flutter-<uuid>.scope) under app.slice, a *sibling* of
#   whatever wrapper you launched it from. The MemoryMax on the wrapper's own
#   scope therefore governs an empty cgroup while Gradle and every
#   gen_snapshot run unbounded next door. Verified 2026-08-19: the build's
#   Gradle process reported memory.max = "max".
#
# So this does both. It starts the command inside a capped scope (correct for
# a tarball/apt Flutter, and for any child that stays put), then watches for a
# *new* snap scope and applies the same ceiling to that. Only scopes that did
# not exist before this script started are touched, so a Flutter or VS Code
# snap you already had running is left alone.
set -uo pipefail

MEM_MAX="${MEM_MAX:-8G}"
NICE_LEVEL="${NICE_LEVEL:-10}"

[[ $# -gt 0 ]] || { echo "usage: MEM_MAX=8G $0 <command> [args…]" >&2; exit 2; }

snap_scopes() {
  systemctl --user list-units --type=scope --no-legend --plain 2>/dev/null \
    | awk '$1 ~ /^snap\./ {print $1}' | sort
}

if ! command -v systemd-run >/dev/null 2>&1; then
  echo "capped_build: systemd-run not found — running uncapped at nice $NICE_LEVEL" >&2
  exec nice -n "$NICE_LEVEL" "$@"
fi

before="$(snap_scopes)"

systemd-run --user --scope -q --description=dayforge-build \
  -p MemoryMax="$MEM_MAX" -p MemorySwapMax=0 \
  -- nice -n "$NICE_LEVEL" "$@" &
build=$!

# Give the snap a moment to claim its scope. 120 polls at 0.25s ≈ 30s, which
# is far longer than `snap run` takes and costs nothing if it never appears.
for _ in $(seq 1 120); do
  kill -0 "$build" 2>/dev/null || break
  new="$(comm -13 <(printf '%s\n' "$before") <(snap_scopes))"
  if [[ -n "$new" ]]; then
    while read -r scope; do
      [[ -n "$scope" ]] || continue
      if systemctl --user set-property --runtime "$scope" \
           MemoryMax="$MEM_MAX" MemorySwapMax=0 2>/dev/null; then
        echo "capped_build: ceiling $MEM_MAX applied to $scope"
      else
        echo "capped_build: WARNING could not cap $scope — build runs unbounded" >&2
      fi
    done <<< "$new"
    break
  fi
  sleep 0.25
done

wait "$build"
