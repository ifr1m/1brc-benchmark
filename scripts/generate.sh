#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROWS="${1:-1000000000}"
OUTPUT="${2:-$ROOT/data/measurements_${ROWS}.txt}"

if [[ ! "$ROWS" =~ ^[1-9][0-9]*$ ]] || (( ROWS > 2147483647 )); then
  echo "rows must be an integer between 1 and 2147483647" >&2
  exit 2
fi
if [[ -e "$OUTPUT" ]]; then
  echo "refusing to overwrite $OUTPUT" >&2
  exit 2
fi

mkdir -p "$ROOT/data" "$(dirname "$OUTPUT")"
WORK="$(mktemp -d "$ROOT/data/generate.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

(
  cd "$WORK"
  java -cp "$ROOT/target/classes" dev.morling.onebrc.CreateMeasurements "$ROWS"
)
mv "$WORK/measurements.txt" "$OUTPUT"
(
  cd "$(dirname "$OUTPUT")"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$(basename "$OUTPUT")" > "$(basename "$OUTPUT").sha256"
  else
    sha256sum "$(basename "$OUTPUT")" > "$(basename "$OUTPUT").sha256"
  fi
)
ls -lh "$OUTPUT"
