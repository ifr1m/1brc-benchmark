#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT="${1:-$ROOT/data/measurements_1000000000.txt}"

if [[ ! -f "$INPUT" ]]; then
  echo "measurement file not found: $INPUT" >&2
  exit 2
fi

TIME_FLAGS=(-p)
if [[ "$(uname -s)" == "Darwin" ]]; then
  TIME_FLAGS=(-lp)
fi

exec /usr/bin/time "${TIME_FLAGS[@]}" dd if="$INPUT" of=/dev/null bs=8388608 iflag=direct
