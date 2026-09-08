#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT="${1:-$ROOT/data/measurements_1000000000.txt}"
LABEL="${2:-$(date -u +%Y%m%dT%H%M%SZ)}"

exec python3 "$ROOT/scripts/benchmark.py" \
  "$INPUT" \
  --warmups "${WARMUPS:-1}" \
  --runs "${RUNS:-10}" \
  --timeout "${RUN_TIMEOUT_SECONDS:-300}" \
  --output "$ROOT/results/$LABEL"
