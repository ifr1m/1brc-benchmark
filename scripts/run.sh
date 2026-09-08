#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT="${1:-$ROOT/data/measurements_1000000000.txt}"

if [[ ! -f "$INPUT" ]]; then
  echo "measurement file not found: $INPUT" >&2
  exit 2
fi

JAVA_OPTS=(
  --enable-native-access=ALL-UNNAMED
  --add-modules=jdk.incubator.vector
  -XX:+UnlockExperimentalVMOptions
  -XX:+UnlockDiagnosticVMOptions
  -XX:-TieredCompilation
  -XX:MaxInlineSize=10000
  -XX:InlineSmallCode=10000
  -XX:FreqInlineSize=10000
  -XX:-UseCountedLoopSafepoints
  -XX:GuaranteedSafepointInterval=0
  -XX:+TrustFinalNonStaticFields
  -da
  -dsa
  -XX:-EnableJVMCI
  -Djdk.incubator.vector.VECTOR_ACCESS_OOB_CHECK=0
  "-Dfile.path=$INPUT"
)

if [[ -f "$ROOT/target/CalculateAverage_serkan_ozal_cds.jsa" ]]; then
  JAVA_OPTS+=("-XX:SharedArchiveFile=$ROOT/target/CalculateAverage_serkan_ozal_cds.jsa")
fi

exec java "${JAVA_OPTS[@]}" -cp "$ROOT/target/average.jar" dev.morling.onebrc.CalculateAverage_serkan_ozal
