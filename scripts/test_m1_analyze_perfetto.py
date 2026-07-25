import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.m1_analyze_perfetto import analyze, percentile


class M1AnalyzePerfettoTest(unittest.TestCase):
    def test_percentile_uses_nearest_rank(self):
        self.assertEqual(percentile([4, 1, 3, 2], 0.95), 4)
        self.assertIsNone(percentile([], 0.95))

    def test_analysis_separates_incomplete_slices(self):
        csv_output = "name,dur\nviewport.bake,-1\nviewport.bake,1000\n"

        def run(command, **_kwargs):
            class Result:
                stdout = "Perfetto v1\n" if "--version" in command else csv_output

            return Result()

        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory) / "trace"
            trace.write_bytes(b"trace")
            with patch("scripts.m1_analyze_perfetto.subprocess.run", side_effect=run):
                result = analyze(
                    Path("trace_processor"),
                    trace,
                    "automatic",
                    require_all=False,
                )

        bake = result["owners"]["viewport.bake"]
        self.assertEqual(bake["samples"], 1)
        self.assertEqual(bake["incomplete"], 1)
        self.assertEqual(bake["p95Micros"], 1.0)
        self.assertIn("history.undo", result["missingRequiredOwners"])

    def test_required_missing_owner_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory) / "trace"
            trace.write_bytes(b"trace")
            with patch("scripts.m1_analyze_perfetto.subprocess.run") as run:
                run.return_value.stdout = "name,dur\n"
                with self.assertRaisesRegex(ValueError, "required owner slices"):
                    analyze(Path("trace_processor"), trace, "manual")


if __name__ == "__main__":
    unittest.main()
