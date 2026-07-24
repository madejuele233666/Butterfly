#!/usr/bin/env python3
"""Summarize an exported M1 JSONL run without inventing device semantics."""

from __future__ import annotations

import argparse
import json
import math
from collections import Counter
from pathlib import Path
from typing import Iterable


def percentile(values: list[int], quantile: float) -> int | None:
    if not values:
        return None
    ordered = sorted(values)
    index = math.ceil(quantile * len(ordered)) - 1
    return ordered[max(0, min(index, len(ordered) - 1))]


def finite(values: Iterable[object]) -> list[float]:
    result: list[float] = []
    for value in values:
        if isinstance(value, (int, float)) and math.isfinite(float(value)):
            result.append(float(value))
    return result


def summarize(records: Iterable[dict[str, object]]) -> dict[str, object]:
    session: dict[str, object] = {}
    native_events = 0
    native_current = 0
    native_history = 0
    flutter_pointers = 0
    pressures: list[float] = []
    tilts: list[float] = []
    orientations: list[float] = []
    refresh_rates: set[float] = set()
    refresh_rate_counts: Counter[str] = Counter()
    refresh_rate_transitions: list[dict[str, object]] = []
    previous_refresh_rate: float | None = None
    native_actions: Counter[str] = Counter()
    flutter_types: Counter[str] = Counter()
    flutter_kinds: Counter[str] = Counter()
    nonzero_buttons: Counter[str] = Counter()
    device_keys: set[tuple[object, ...]] = set()
    key_events = 0
    key_actions: Counter[str] = Counter()
    key_codes: Counter[str] = Counter()
    scan_codes: Counter[str] = Counter()
    repeated_key_events = 0
    max_repeat_count = 0
    key_devices: set[tuple[object, ...]] = set()
    frame_build: list[int] = []
    frame_raster: list[int] = []
    frame_total: list[int] = []

    for record in records:
        schema = record.get("schema")
        if schema == "notea.m1.session/v1":
            session = record
        elif schema == "notea.m1.motion/v1":
            native_events += 1
            native_actions[str(record.get("actionMasked"))] += 1
            event_refresh_rates = finite([record.get("refreshRateHz")])
            refresh_rates.update(event_refresh_rates)
            if event_refresh_rates:
                refresh_rate = event_refresh_rates[0]
                refresh_rate_counts[str(refresh_rate)] += 1
                if (
                    previous_refresh_rate is not None
                    and refresh_rate != previous_refresh_rate
                ):
                    refresh_rate_transitions.append(
                        {
                            "nativeEvent": native_events,
                            "eventTimeNanos": record.get("eventTimeNanos"),
                            "fromHz": previous_refresh_rate,
                            "toHz": refresh_rate,
                        }
                    )
                previous_refresh_rate = refresh_rate
            device = record.get("device")
            if isinstance(device, dict):
                device_keys.add(
                    (
                        device.get("id"),
                        device.get("vendorId"),
                        device.get("productId"),
                        device.get("descriptor"),
                    )
                )
            for key in ("buttonState", "actionButton"):
                value = record.get(key)
                if isinstance(value, int) and value != 0:
                    nonzero_buttons[f"{key}:{value}"] += 1
            pointers = record.get("pointers")
            if not isinstance(pointers, list):
                continue
            native_current += len(pointers)
            for pointer in pointers:
                if not isinstance(pointer, dict):
                    continue
                samples = [pointer]
                history = pointer.get("history")
                if isinstance(history, list):
                    native_history += len(history)
                    samples.extend(item for item in history if isinstance(item, dict))
                pressures.extend(finite(sample.get("pressure") for sample in samples))
                tilts.extend(finite(sample.get("tilt") for sample in samples))
                orientations.extend(
                    finite(sample.get("orientation") for sample in samples)
                )
        elif schema == "notea.m1.key/v1":
            key_events += 1
            key_actions[str(record.get("action"))] += 1
            key_codes[str(record.get("keyCode"))] += 1
            scan_codes[str(record.get("scanCode"))] += 1
            repeat_count = record.get("repeatCount")
            if isinstance(repeat_count, int):
                max_repeat_count = max(max_repeat_count, repeat_count)
                if repeat_count > 0:
                    repeated_key_events += 1
            device = record.get("device")
            if isinstance(device, dict):
                key_devices.add(
                    (
                        device.get("id"),
                        device.get("name"),
                        device.get("vendorId"),
                        device.get("productId"),
                        device.get("descriptor"),
                        device.get("sources"),
                    )
                )
        elif schema == "notea.m1.pointer/v1":
            flutter_pointers += 1
            flutter_types[str(record.get("eventType"))] += 1
            flutter_kinds[str(record.get("kind"))] += 1
        elif schema == "notea.m1.frame/v1":
            for target, key in (
                (frame_build, "buildMicros"),
                (frame_raster, "rasterMicros"),
                (frame_total, "totalMicros"),
            ):
                value = record.get(key)
                if isinstance(value, int):
                    target.append(value)

    def range_of(values: list[float]) -> dict[str, float] | None:
        return {"min": min(values), "max": max(values)} if values else None

    def frame_stats(values: list[int]) -> dict[str, int | None]:
        return {
            "count": len(values),
            "p50_us": percentile(values, 0.50),
            "p90_us": percentile(values, 0.90),
            "p95_us": percentile(values, 0.95),
            "p99_us": percentile(values, 0.99),
        }

    native_total = native_current + native_history
    return {
        "schema": "notea.m1.probe-summary/v1",
        "sessionId": session.get("sessionId"),
        "loss": {
            "native": (session.get("nativeStatus") or {}).get("dropped")
            if isinstance(session.get("nativeStatus"), dict)
            else None,
            "flutter": (session.get("flutterStatus") or {}).get("dropped")
            if isinstance(session.get("flutterStatus"), dict)
            else None,
        },
        "motion": {
            "nativeEvents": native_events,
            "nativeCurrentSamples": native_current,
            "nativeHistoricalSamples": native_history,
            "nativeTotalSamples": native_total,
            "flutterPointerEvents": flutter_pointers,
            "flutterToNativeSampleRatio": (
                flutter_pointers / native_total if native_total else None
            ),
            "pressure": range_of(pressures),
            "tilt": range_of(tilts),
            "orientation": range_of(orientations),
            "refreshRatesHz": sorted(refresh_rates),
            "refreshRateEventCounts": dict(sorted(refresh_rate_counts.items())),
            "refreshRateTransitions": refresh_rate_transitions,
            "nativeActions": dict(sorted(native_actions.items())),
            "flutterTypes": dict(sorted(flutter_types.items())),
            "flutterKinds": dict(sorted(flutter_kinds.items())),
            "nonzeroButtons": dict(sorted(nonzero_buttons.items())),
            "devices": [list(item) for item in sorted(device_keys, key=str)],
        },
        "keys": {
            "nativeEvents": key_events,
            "actions": dict(sorted(key_actions.items())),
            "keyCodes": dict(sorted(key_codes.items())),
            "scanCodes": dict(sorted(scan_codes.items())),
            "repeatedEvents": repeated_key_events,
            "maxRepeatCount": max_repeat_count,
            "devices": [list(item) for item in sorted(key_devices, key=str)],
        },
        "frames": {
            "build": frame_stats(frame_build),
            "raster": frame_stats(frame_raster),
            "total": frame_stats(frame_total),
        },
        "interpretation": (
            "Counts and ranges are observations only. A sample difference or "
            "button value requires action-matrix correlation before assigning semantics."
        ),
    }


def load_jsonl(path: Path) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    with path.open("r", encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, 1):
            if not line.strip():
                continue
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError(f"line {line_number} is not a JSON object")
            records.append(value)
    return records


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()
    result = summarize(load_jsonl(args.input))
    encoded = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(encoded, encoding="utf-8")
    else:
        print(encoded, end="")


if __name__ == "__main__":
    main()
