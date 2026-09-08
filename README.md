# 1BRC machine baseline

This standalone project runs Serkan Özal's accepted 1BRC implementation against one billion generated measurements. It calibrates the upper end of byte scanning and aggregation on the machine used for the Leadgidi parser experiments.

## Recorded result

Recorded on 2026-09-07:

| Measurement | Result |
| --- | ---: |
| Rows | 1,000,000,000 |
| File size | 13,795,461,445 bytes, 12.85 GiB |
| First JVM run before the measured set | 5.428 s |
| Fastest measured run | 1.342 s |
| Median of 10 runs | 1.433 s |
| Trimmed mean, fastest and slowest removed | 1.444 s |
| Median record rate | 697,958,248 rows/s |
| Median input rate | 9.629 GB/s, 8.967 GiB/s |
| Direct SSD read with `F_NOCACHE` | 11.822 GB/s, 1.167 s |
| Published Serkan Özal result | 1.880 s |

Raw timings in seconds:

```text
1.485527917
1.353152791
1.533362709
1.422388875
1.409083750
1.342390166
1.509406333
1.503593583
1.431374666
1.434126250
```

The local trimmed mean is 23.2% lower than the published 1.880-second result. A later clean invocation of `scripts/rerun.sh` regenerated all one billion rows and completed all ten measurements successfully. That independent run produced a 1.451-second median and 1.443946-second trimmed mean, within 0.03% of the first trimmed mean. Its direct SSD read reached 13.556 GB/s. The full rerun evidence is under `results/rerun-validation-20260907/`.

That does not mean the implementation is universally 23.2% faster here. The environments differ:

- Local machine: Apple M2 Max, 12 CPU cores, 64 GiB, Apple Fabric SSD, macOS 15.7.3, Corretto JDK 25.0.2.
- Published machine: eight assigned cores of an AMD EPYC 7502P Zen 2 server with 128 GB RAM, JDK 21.0.1.
- The published evaluation warmed the full input before timing. The local measured set also follows one full warmup, so its 1.433-second median is primarily a page-cache and CPU result.
- The first local full run took 5.428 seconds. It includes JVM startup, page faults, and storage effects, but it is not a controlled cold-cache number because macOS cache state was not reset.
- A separate `dd iflag=direct` run bypassed the file cache and read the 12.85 GiB file in 1.167 seconds. That measures sequential SSD transfer, not parsing.

This is a machine ceiling, not a target for Leadgidi. The 1BRC program reduces one billion fixed-format rows to roughly 400 aggregates and uses memory mapping, `Unsafe`, SIMD, fixed slots, and no per-row output. Leadgidi must preserve and persist every CSV or NDJSON row.

## Source identity

The project was copied from `gunnarmorling/1brc` revision:

```text
db064194be375edc02d6dbcd21268ad40f7e2869
```

`CalculateAverage_serkan_ozal.java` is byte-for-byte identical to the file supplied in `backend/temp/`:

```text
fe086c3511ee98d857d593c20ce6309214dd329c1a236a397afcff2e024911a1
```

The two copied Java files retain their Apache License 2.0 headers. The upstream repository license is included as `LICENSE.txt`.

## Layout

```text
src/main/java/dev/morling/onebrc/
  CalculateAverage_serkan_ozal.java
  CreateMeasurements.java
scripts/
  build.sh
  generate.sh
  prepare-cds.sh
  run.sh
  benchmark.sh
  benchmark.py
  disk-baseline.sh
  clean-data.sh
data/
results/
target/
```

The generated billion-row file consumed about 13 GB and was removed after recording the baseline. Its SHA-256 remains in `results/m2-max-1b-jdk25/result.json`. Run `scripts/generate.sh 1000000000` to reproduce it; `scripts/clean-data.sh` removes generated datasets afterward.

## Reproduce

From this project directory, one command rebuilds the code, regenerates the dataset when absent, prepares CDS, runs one warmup and ten measurements, and measures direct SSD reading:

```bash
scripts/rerun.sh
```

The billion-row dataset takes about three minutes to generate on this machine and occupies about 13 GB. Subsequent reruns reuse it. Override defaults when needed:

```bash
ROWS=1000000 RUNS=3 WARMUPS=1 LABEL=smoke scripts/rerun.sh
```

The equivalent individual commands are:

```bash
scripts/build.sh
scripts/generate.sh 1000000000
scripts/prepare-cds.sh data/measurements_1000000000.txt
RUNS=10 WARMUPS=1 scripts/benchmark.sh \
  data/measurements_1000000000.txt \
  "$(date -u +%Y%m%dT%H%M%SZ)"
scripts/disk-baseline.sh data/measurements_1000000000.txt
```

`benchmark.py` runs each measurement in a fresh JVM, checks that every output has the same SHA-256, and writes immutable JSON results. It reports the same trimmed-mean rule used by upstream `evaluate.sh`: discard the fastest and slowest values, then average the rest.

## Evidence

- `results/m2-max-1b-jdk25/result.json`: machine-readable application timing.
- `results/benchmark-1b-console.log`: individual runs and process resource output.
- `results/ssd-direct-read.log`: first direct SSD read measurement.
- `results/rerun-validation-20260907/`: complete independently regenerated rerun and direct SSD measurement.
- `results/generate-1b.log`: generation duration and progress.
- `results/environment.txt`: hardware, OS, JDK, disk, and upstream revision.
- `results/manifest.sha256`: evidence checksums.

The 13 GB generated input was removed after measurement. Its SHA-256 is preserved in the machine-readable benchmark result.
