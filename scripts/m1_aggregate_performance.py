#!/usr/bin/env python3
"""Aggregate three valid M1 per-run performance summaries."""

from __future__ import annotations

import argparse
import hashlib
import json
import statistics
from pathlib import Path
from typing import Any


def _load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return value


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def aggregate(
    owner_runs: list[dict[str, Any]], probe_runs: list[dict[str, Any]]
) -> dict[str, Any]:
    if len(owner_runs) != 3 or len(probe_runs) != 3:
        raise ValueError("exactly three owner and three probe runs are required")

    owner_names = list(owner_runs[0].get("owners", {}))
    if not owner_names:
        raise ValueError("owner run 1 has no owners")
    for index, run in enumerate(owner_runs, 1):
        if run.get("missingRequiredOwners"):
            raise ValueError(f"owner run {index} has missing required owners")
        if list(run.get("owners", {})) != owner_names:
            raise ValueError(f"owner run {index} has a different owner set")

    owner_baseline = {}
    for name in owner_names:
        per_run = []
        for index, run in enumerate(owner_runs, 1):
            metrics = run["owners"][name]
            if metrics.get("samples", 0) < 1 or metrics.get("incomplete", 0) != 0:
                raise ValueError(f"owner {name} run {index} is incomplete")
            per_run.append(
                {
                    key: metrics[key]
                    for key in ("samples", "p50Micros", "p95Micros", "p99Micros")
                }
            )
        owner_baseline[name] = {
            "runs": per_run,
            "medianP50Micros": statistics.median(
                run["p50Micros"] for run in per_run
            ),
            "medianP95Micros": statistics.median(
                run["p95Micros"] for run in per_run
            ),
            "medianP99Micros": statistics.median(
                run["p99Micros"] for run in per_run
            ),
        }

    frame_baseline = {}
    for index, run in enumerate(probe_runs, 1):
        loss = run.get("loss", {})
        if loss.get("native") != 0 or loss.get("flutter") != 0:
            raise ValueError(f"probe run {index} reports dropped records")
    for metric in ("build", "raster", "total"):
        per_run = []
        for index, run in enumerate(probe_runs, 1):
            frames = run.get("frames", {}).get(metric, {})
            if frames.get("count", 0) < 1:
                raise ValueError(f"probe run {index} has no {metric} frames")
            per_run.append(
                {
                    key: frames[key]
                    for key in ("count", "p50_us", "p95_us", "p99_us")
                }
            )
        frame_baseline[metric] = {
            "runs": per_run,
            "medianP50Micros": statistics.median(run["p50_us"] for run in per_run),
            "medianP95Micros": statistics.median(run["p95_us"] for run in per_run),
            "medianP99Micros": statistics.median(run["p99_us"] for run in per_run),
        }

    return {
        "schema": "notea.m1.performance-baseline/v1",
        "comparisonStatistic": "median of three per-run percentiles",
        "percentileMethod": "nearest-rank-v1",
        "ownerSlices": owner_baseline,
        "frames": frame_baseline,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--owner-analysis", type=Path, nargs=3, required=True)
    parser.add_argument("--probe-analysis", type=Path, nargs=3, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    result = aggregate(
        [_load(path) for path in args.owner_analysis],
        [_load(path) for path in args.probe_analysis],
    )
    result["inputs"] = {
        "ownerAnalysis": [
            {"path": str(path), "sha256": _sha256(path)}
            for path in args.owner_analysis
        ],
        "probeAnalysis": [
            {"path": str(path), "sha256": _sha256(path)}
            for path in args.probe_analysis
        ],
    }
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
