import unittest

from scripts.m1_analyze_probe import percentile, summarize


class ProbeSummaryTest(unittest.TestCase):
    def test_summary_keeps_history_and_flutter_counts_distinct(self):
        result = summarize(
            [
                {
                    "schema": "notea.m1.session/v1",
                    "sessionId": "test",
                    "nativeStatus": {"dropped": 1},
                    "flutterStatus": {"dropped": 2},
                },
                {
                    "schema": "notea.m1.motion/v1",
                    "actionMasked": 2,
                    "refreshRateHz": 120.0,
                    "buttonState": 32,
                    "actionButton": 0,
                    "pointers": [
                        {
                            "pressure": 0.8,
                            "tilt": 0.2,
                            "orientation": 0.3,
                            "history": [
                                {
                                    "pressure": 0.4,
                                    "tilt": 0.1,
                                    "orientation": 0.2,
                                }
                            ],
                        }
                    ],
                },
                {
                    "schema": "notea.m1.pointer/v1",
                    "eventType": "PointerMoveEvent",
                    "kind": "stylus",
                },
                {
                    "schema": "notea.m1.key/v1",
                    "action": 0,
                    "keyCode": 334,
                    "scanCode": 191,
                    "repeatCount": 2,
                    "device": {
                        "id": 12,
                        "name": "OnePlus Pencil",
                        "vendorId": 13066,
                        "productId": 1,
                        "descriptor": "pencil",
                        "sources": 257,
                    },
                },
                {
                    "schema": "notea.m1.frame/v1",
                    "buildMicros": 1000,
                    "rasterMicros": 2000,
                    "totalMicros": 3000,
                },
            ]
        )
        motion = result["motion"]
        self.assertEqual(motion["nativeCurrentSamples"], 1)
        self.assertEqual(motion["nativeHistoricalSamples"], 1)
        self.assertEqual(motion["flutterPointerEvents"], 1)
        self.assertEqual(motion["pressure"], {"min": 0.4, "max": 0.8})
        self.assertEqual(motion["refreshRateEventCounts"], {"120.0": 1})
        self.assertEqual(motion["refreshRateTransitions"], [])
        self.assertEqual(result["loss"], {"native": 1, "flutter": 2})
        self.assertEqual(
            result["keys"],
            {
                "nativeEvents": 1,
                "actions": {"0": 1},
                "keyCodes": {"334": 1},
                "scanCodes": {"191": 1},
                "repeatedEvents": 1,
                "maxRepeatCount": 2,
                "devices": [
                    [12, "OnePlus Pencil", 13066, 1, "pencil", 257]
                ],
            },
        )

    def test_percentile_uses_nearest_rank(self):
        self.assertEqual(percentile([4, 1, 3, 2], 0.95), 4)
        self.assertIsNone(percentile([], 0.95))


if __name__ == "__main__":
    unittest.main()
