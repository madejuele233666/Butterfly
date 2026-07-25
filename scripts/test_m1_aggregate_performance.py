import unittest

from scripts.m1_aggregate_performance import aggregate


def owner_run(value: float, *, incomplete: int = 0) -> dict:
    return {
        "missingRequiredOwners": [],
        "owners": {
            "owner": {
                "samples": 1,
                "incomplete": incomplete,
                "p50Micros": value,
                "p95Micros": value + 1,
                "p99Micros": value + 2,
            }
        },
    }


def probe_run(value: int, *, dropped: int = 0) -> dict:
    frames = {
        "count": 1,
        "p50_us": value,
        "p95_us": value + 1,
        "p99_us": value + 2,
    }
    return {
        "loss": {"native": dropped, "flutter": 0},
        "frames": {"build": frames, "raster": frames, "total": frames},
    }


class M1AggregatePerformanceTest(unittest.TestCase):
    def test_uses_middle_per_run_percentile(self):
        result = aggregate(
            [owner_run(30), owner_run(10), owner_run(20)],
            [probe_run(300), probe_run(100), probe_run(200)],
        )
        self.assertEqual(result["ownerSlices"]["owner"]["medianP95Micros"], 21)
        self.assertEqual(result["frames"]["build"]["medianP95Micros"], 201)

    def test_rejects_incomplete_owner(self):
        with self.assertRaisesRegex(ValueError, "incomplete"):
            aggregate(
                [owner_run(1), owner_run(2, incomplete=1), owner_run(3)],
                [probe_run(1), probe_run(2), probe_run(3)],
            )

    def test_rejects_probe_loss(self):
        with self.assertRaisesRegex(ValueError, "dropped"):
            aggregate(
                [owner_run(1), owner_run(2), owner_run(3)],
                [probe_run(1), probe_run(2, dropped=1), probe_run(3)],
            )


if __name__ == "__main__":
    unittest.main()
