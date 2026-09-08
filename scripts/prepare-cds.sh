#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLE="${1:-$ROOT/data/measurements_1000000.txt}"
CLASS_NAME="CalculateAverage_serkan_ozal"
CLASS_LIST="$ROOT/target/${CLASS_NAME}.classlist"
BASE_ARCHIVE="$ROOT/target/${CLASS_NAME}.jsa"
FINAL_ARCHIVE="$ROOT/target/${CLASS_NAME}_cds.jsa"

if [[ ! -f "$SAMPLE" ]]; then
  echo "sample measurement file not found: $SAMPLE" >&2
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
  "-Dfile.path=$SAMPLE"
)

rm -f "$CLASS_LIST" "$BASE_ARCHIVE" "$FINAL_ARCHIVE"
java "${JAVA_OPTS[@]}" \
  -Xshare:off \
  "-XX:DumpLoadedClassList=$CLASS_LIST" \
  -cp "$ROOT/target/average.jar" \
  "dev.morling.onebrc.$CLASS_NAME" \
  >/dev/null

java "${JAVA_OPTS[@]}" \
  -Xshare:dump \
  "-XX:SharedClassListFile=$CLASS_LIST" \
  "-XX:SharedArchiveFile=$BASE_ARCHIVE" \
  -cp "$ROOT/target/average.jar"

java "${JAVA_OPTS[@]}" \
  -Xshare:on \
  "-XX:SharedArchiveFile=$BASE_ARCHIVE" \
  "-XX:ArchiveClassesAtExit=$FINAL_ARCHIVE" \
  -cp "$ROOT/target/average.jar" \
  "dev.morling.onebrc.$CLASS_NAME" \
  >/dev/null

ls -lh "$FINAL_ARCHIVE"
