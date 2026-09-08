#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import platform
import statistics
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


def timed_run(command: list[str], timeout: int) -> tuple[float, bytes]:
    started = time.perf_counter_ns()
    completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=True)
    elapsed = (time.perf_counter_ns() - started) / 1_000_000_000
    if completed.stderr:
        print(completed.stderr.decode(errors="replace"), end="", file=os.sys.stderr)
    return elapsed, completed.stdout


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(8 * 1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--warmups", type=int, default=1)
    parser.add_argument("--runs", type=int, default=10)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    command = [str(root / "scripts" / "run.sh"), str(args.input.resolve())]
    args.output.mkdir(parents=True, exist_ok=False)

    warmups = []
    expected_hash = None
    for index in range(args.warmups):
        elapsed, output = timed_run(command, args.timeout)
        output_hash = hashlib.sha256(output).hexdigest()
        expected_hash = expected_hash or output_hash
        if output_hash != expected_hash:
            raise RuntimeError("warmup output checksum changed")
        warmups.append(elapsed)
        print(f"warmup {index + 1}: {elapsed:.6f}s")

    times = []
    for index in range(args.runs):
        elapsed, output = timed_run(command, args.timeout)
        output_hash = hashlib.sha256(output).hexdigest()
        expected_hash = expected_hash or output_hash
        if output_hash != expected_hash:
            raise RuntimeError("measured output checksum changed")
        times.append(elapsed)
        print(f"run {index + 1}: {elapsed:.6f}s")

    sorted_times = sorted(times)
    trimmed = sorted_times[1:-1] if len(sorted_times) >= 3 else sorted_times
    input_bytes = args.input.stat().st_size
    result = {
        "schemaVersion": 1,
        "recordedAt": datetime.now(timezone.utc).isoformat(),
        "host": platform.node(),
        "platform": platform.platform(),
        "machine": platform.machine(),
        "input": str(args.input.resolve()),
        "inputBytes": input_bytes,
        "inputSha256": sha256_file(args.input),
        "command": command,
        "warmupSeconds": warmups,
        "timesSeconds": times,
        "minimumSeconds": min(times),
        "medianSeconds": statistics.median(times),
        "meanSeconds": statistics.mean(times),
        "trimmedMeanSeconds": statistics.mean(trimmed),
        "standardDeviationSeconds": statistics.stdev(times) if len(times) > 1 else 0.0,
        "medianGiBPerSecond": input_bytes / statistics.median(times) / (1024 ** 3),
        "outputSha256": expected_hash,
    }
    (args.output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    (args.output / "output.sha256").write_text(expected_hash + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
