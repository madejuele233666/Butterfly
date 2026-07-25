#!/usr/bin/env python3
"""Extract reproducible M1 owner-slice percentiles from a Perfetto trace."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import math
import subprocess
from pathlib import Path


OWNER_SETS = {
    "automatic": (
        "m1.oracle.create-stroke",
        "m1.oracle.erase-strokes",
        "m1.oracle.partial-erase",
        "m1.oracle.translate-selection",
        "history.undo",
        "history.redo",
        "selection.raycast",
        "viewport.bake",
    ),
    "manual": (
        "stroke.foreground.update",
        "stroke.commit",
        "document.save",
    ),
}


def percentile(values: list[int], quantile: float) -> int | None:
    if not values:
        return None
    ordered = sorted(values)
    index = math.ceil(quantile * len(ordered)) - 1
    return ordered[max(index, 0)]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def analyze(
    trace_processor: Path,
    trace: Path,
    owner_set: str,
    require_all: bool = True,
) -> dict[str, object]:
    owners = OWNER_SETS[owner_set]
    names = ",".join("'" + name.replace("'", "''") + "'" for name in owners)
    query = (
        "SELECT name, dur FROM slice "
        f"WHERE name IN ({names}) ORDER BY name, dur;"
    )
    completed = subprocess.run(
        [str(trace_processor), "query", str(trace), query],
        check=True,
        capture_output=True,
        text=True,
    )
    durations: dict[str, list[int]] = {name: [] for name in owners}
    incomplete: dict[str, int] = {name: 0 for name in owners}
    for row in csv.DictReader(io.StringIO(completed.stdout)):
        name = row["name"]
        duration = int(row["dur"])
        if duration < 0:
            incomplete[name] += 1
        else:
            durations[name].append(duration)

    missing = [name for name, values in durations.items() if not values]
    if require_all and missing:
        raise ValueError("required owner slices are absent: " + ", ".join(missing))

    def micros(value: int | None) -> float | None:
        return None if value is None else round(value / 1000.0, 3)

    metrics = {}
    for name in owners:
        values = durations[name]
        metrics[name] = {
            "samples": len(values),
            "incomplete": incomplete[name],
            "p50Micros": micros(percentile(values, 0.50)),
            "p95Micros": micros(percentile(values, 0.95)),
            "p99Micros": micros(percentile(values, 0.99)),
            "maxMicros": micros(max(values) if values else None),
        }

    version = subprocess.run(
        [str(trace_processor), "--version"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    return {
        "schema": "notea.m1.perfetto-owner-analysis/v1",
        "ownerSet": owner_set,
        "percentileMethod": "nearest-rank-v1",
        "trace": str(trace),
        "traceSha256": _sha256(trace),
        "traceProcessorVersion": version,
        "owners": metrics,
        "missingRequiredOwners": missing,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace", type=Path)
    parser.add_argument("--trace-processor", required=True, type=Path)
    parser.add_argument("--owner-set", choices=OWNER_SETS, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--allow-missing", action="store_true")
    args = parser.parse_args()

    result = analyze(
        args.trace_processor,
        args.trace,
        args.owner_set,
        require_all=not args.allow_missing,
    )
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
