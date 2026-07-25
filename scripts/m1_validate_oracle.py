#!/usr/bin/env python3
"""Validate deterministic M1 Legacy oracle sessions before M2 cutover."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def _load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return value


def _comparable_run(run: dict[str, Any]) -> dict[str, Any]:
    return {
        "initialFixtureHash": run.get("initialFixtureHash"),
        "steps": [
            {
                key: step.get(key)
                for key in (
                    "name",
                    "sequenceRevision",
                    "historyPosition",
                    "historyHead",
                    "canUndo",
                    "canRedo",
                    "stateHash",
                    "elementCount",
                    "layerOrder",
                    "delta",
                )
            }
            for step in run.get("steps", [])
        ],
    }


def validate_session(
    session: dict[str, Any], rules: dict[str, Any]
) -> dict[str, Any]:
    errors: list[str] = []
    behavior = rules["behavior"]
    runs = session.get("runs")
    if session.get("schema") != "notea.m1.baseline-session/v1":
        errors.append("unexpected session schema")
    if session.get("replayVersion") != behavior["replayVersion"]:
        errors.append("replay version does not match frozen rules")
    if session.get("normalizationVersion") != behavior["normalizationVersion"]:
        errors.append("normalization version does not match frozen rules")
    if session.get("decisionRulesVersion") != rules["version"]:
        errors.append("decision rules version does not match frozen rules")
    if not isinstance(runs, list):
        errors.append("runs must be a list")
        runs = []
    minimum = behavior["minimumRunsPerFixture"]
    if len(runs) < minimum:
        errors.append(f"requires at least {minimum} runs, found {len(runs)}")
    if session.get("completedRuns") != len(runs):
        errors.append("completedRuns does not equal retained runs")

    expected_steps = behavior["requiredSteps"]
    for index, run in enumerate(runs, 1):
        names = [step.get("name") for step in run.get("steps", [])]
        if names != expected_steps:
            errors.append(f"run {index}: step sequence differs from frozen rules")
        if run.get("fixture") != session.get("fixture"):
            errors.append(f"run {index}: fixture differs from session fixture")

    if runs:
        accepted = _comparable_run(runs[0])
        for index, run in enumerate(runs[1:], 2):
            if _comparable_run(run) != accepted:
                errors.append(f"run {index}: normalized oracle differs from run 1")

    return {
        "schema": "notea.m1.oracle-validation/v1",
        "fixture": session.get("fixture"),
        "runs": len(runs),
        "rulesVersion": rules.get("version"),
        "valid": not errors,
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("session", type=Path)
    parser.add_argument(
        "--rules",
        type=Path,
        default=Path("artifacts/m1/M1_M2_DECISION_RULES.json"),
    )
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()

    result = validate_session(_load(args.session), _load(args.rules))
    rendered = json.dumps(result, indent=2, sort_keys=True)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if result["valid"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
