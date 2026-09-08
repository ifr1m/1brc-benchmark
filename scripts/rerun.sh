#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DISK_BASELINE="${RUN_DISK_BASELINE:-1}"
ROWS="${ROWS:-1000000000}"
INPUT="$ROOT/data/measurements_${ROWS}.txt"
LABEL="${LABEL:-$(date -u +%Y%m%dT%H%M%SZ)}"

RUN_DISK_BASELINE="$RUN_DISK_BASELINE" "$ROOT/scripts/doctor.sh"
"$ROOT/scripts/build.sh"
if [[ ! -f "$INPUT" ]]; then
  "$ROOT/scripts/generate.sh" "$ROWS" "$INPUT"
fi
"$ROOT/scripts/prepare-cds.sh" "$INPUT"
RUNS="${RUNS:-10}" WARMUPS="${WARMUPS:-1}" RUN_TIMEOUT_SECONDS="${RUN_TIMEOUT_SECONDS:-300}" \
  "$ROOT/scripts/benchmark.sh" "$INPUT" "$LABEL"

if [[ "$RUN_DISK_BASELINE" == "1" ]]; then
  "$ROOT/scripts/disk-baseline.sh" "$INPUT" > "$ROOT/results/$LABEL/ssd-direct-read.log" 2>&1
  printf 'Disk baseline: %s\n' "$ROOT/results/$LABEL/ssd-direct-read.log"
else
  printf 'Disk baseline: skipped (RUN_DISK_BASELINE=0)\n'
fi

printf '\nResults: %s\n' "$ROOT/results/$LABEL/result.json"
