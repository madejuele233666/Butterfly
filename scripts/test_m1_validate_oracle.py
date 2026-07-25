import copy
import json
import unittest
from pathlib import Path

from scripts.m1_validate_oracle import combine_sessions, validate_session


RULES = json.loads(
    Path("artifacts/m1/M1_M2_DECISION_RULES.json").read_text(encoding="utf-8")
)


def step(name: str, revision: int) -> dict:
    return {
        "name": name,
        "sequenceRevision": revision,
        "historyPosition": revision,
        "historyHead": revision,
        "canUndo": revision > 0,
        "canRedo": False,
        "stateHash": f"hash-{revision}",
        "elementCount": revision,
        "layerOrder": {"m1-layer": []},
        "delta": {"created": [], "updated": [], "removed": []},
    }


def session() -> dict:
    run = {
        "fixture": "F0",
        "initialFixtureHash": "fixture-hash",
        "steps": [step(name, index) for index, name in enumerate(RULES["behavior"]["requiredSteps"])],
    }
    runs = [copy.deepcopy(run) for _ in range(3)]
    return {
        "schema": "notea.m1.baseline-session/v1",
        "fixture": "F0",
        "completedRuns": 3,
        "replayVersion": RULES["behavior"]["replayVersion"],
        "normalizationVersion": RULES["behavior"]["normalizationVersion"],
        "decisionRulesVersion": RULES["version"],
        "runs": runs,
    }


class OracleValidationTest(unittest.TestCase):
    def test_accepts_three_identical_runs(self):
        result = validate_session(session(), RULES)
        self.assertTrue(result["valid"], result["errors"])

    def test_rejects_step_mismatch(self):
        value = session()
        value["runs"][1]["steps"][2]["stateHash"] = "different"
        result = validate_session(value, RULES)
        self.assertFalse(result["valid"])
        self.assertIn("run 2: normalized oracle differs from run 1", result["errors"])

    def test_rejects_missing_run(self):
        value = session()
        value["runs"].pop()
        value["completedRuns"] = 2
        result = validate_session(value, RULES)
        self.assertFalse(result["valid"])

    def test_combines_independent_single_run_sessions(self):
        values = []
        for run in session()["runs"]:
            value = session()
            value["runs"] = [run]
            value["completedRuns"] = 1
            values.append(value)
        combined = combine_sessions(values)
        result = validate_session(combined, RULES)
        self.assertTrue(result["valid"], result["errors"])

    def test_combine_rejects_identity_mismatch(self):
        first = session()
        second = session()
        second["fixture"] = "F50"
        with self.assertRaisesRegex(ValueError, "fixture differs"):
            combine_sessions([first, second])


if __name__ == "__main__":
    unittest.main()
