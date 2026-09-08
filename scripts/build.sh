#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rm -rf "$ROOT/target/classes"
rm -f \
  "$ROOT/target/CalculateAverage_serkan_ozal.classlist" \
  "$ROOT/target/CalculateAverage_serkan_ozal.jsa" \
  "$ROOT/target/CalculateAverage_serkan_ozal_cds.jsa"
mkdir -p "$ROOT/target/classes"

javac \
  --add-modules jdk.incubator.vector \
  -d "$ROOT/target/classes" \
  "$ROOT/src/main/java/dev/morling/onebrc/CalculateAverage_serkan_ozal.java" \
  "$ROOT/src/main/java/dev/morling/onebrc/CreateMeasurements.java"

jar --create --file "$ROOT/target/average.jar" -C "$ROOT/target/classes" .
