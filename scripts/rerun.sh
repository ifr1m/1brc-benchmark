#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROWS="${ROWS:-1000000000}"
INPUT="$ROOT/data/measurements_${ROWS}.txt"
LABEL="${LABEL:-$(date -u +%Y%m%dT%H%M%SZ)}"

"$ROOT/scripts/build.sh"
if [[ ! -f "$INPUT" ]]; then
  "$ROOT/scripts/generate.sh" "$ROWS" "$INPUT"
fi
"$ROOT/scripts/prepare-cds.sh" "$INPUT"
RUNS="${RUNS:-10}" WARMUPS="${WARMUPS:-1}" RUN_TIMEOUT_SECONDS="${RUN_TIMEOUT_SECONDS:-300}" \
  "$ROOT/scripts/benchmark.sh" "$INPUT" "$LABEL"
"$ROOT/scripts/disk-baseline.sh" "$INPUT" > "$ROOT/results/$LABEL/ssd-direct-read.log" 2>&1

printf '\nResults: %s\n' "$ROOT/results/$LABEL/result.json"
printf 'Disk baseline: %s\n' "$ROOT/results/$LABEL/ssd-direct-read.log"
