#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rm -f "$ROOT"/data/measurements_*.txt "$ROOT"/data/measurements_*.txt.sha256
