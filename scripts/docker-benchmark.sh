#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-1brc-benchmark:local}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required; install Docker and start the Docker daemon" >&2
  exit 2
fi

mkdir -p "$ROOT/data" "$ROOT/results"

docker build --tag "$IMAGE" "$ROOT"

exec docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env "ROWS=${ROWS:-1000000000}" \
  --env "RUNS=${RUNS:-10}" \
  --env "WARMUPS=${WARMUPS:-1}" \
  --env "RUN_TIMEOUT_SECONDS=${RUN_TIMEOUT_SECONDS:-300}" \
  --env "LABEL=${LABEL:-}" \
  --env "RUN_DISK_BASELINE=${RUN_DISK_BASELINE:-0}" \
  --volume "$ROOT/data:/benchmark/data" \
  --volume "$ROOT/results:/benchmark/results" \
  "$IMAGE"
