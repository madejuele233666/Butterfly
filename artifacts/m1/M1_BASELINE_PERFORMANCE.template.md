# M1 baseline performance report

Status: pending physical measurements.

## M2 ownership-cutover gate

- Legacy oracle/replay version:
- Covered commands: CreateStroke / EraseStrokes / PartialErase /
  TranslateSelection / Undo / Redo / cancel-no-commit / save-reload
- Normalized state, history cursor, revision and Delta artifact:
- Empty fixture hash and three run IDs:
- Representative stress fixture hash and three run IDs:
- Pre-frozen behavior equality rule:
- Pre-frozen performance regression rule:
- Observed owner traces:

This section is required before the first M2 Handler cutover. The broader
cross-product and six-red-line sections below are filled only when a later
product, M7 or M8 decision needs them.

## Run identity

- Application/build:
- Git commit:
- APK SHA-256:
- Device model/build fingerprint:
- Android/API:
- Refresh mode:
- Battery and thermal state:
- Performance/power mode:
- Mirroring/recording/inspector state:
- Fixture and fixture SHA-256:
- Replayed action path/version:

## Compared builds

| Build | package/version | configuration parity | retained evidence |
|---|---|---|---|
| Notein | | | |
| Butterfly v2.5.3 pristine | | | |
| Notea current | | | |

## Six performance red lines

| Red line | Metric and method | Notein | Butterfly | Notea | Interpretation |
|---|---|---:|---:|---:|---|
| Visible ink lag | 240/480 fps contact, max gap, lift tail | | | | |
| Sample loss/distortion | native current+history vs Flutter/raw points | | | | |
| Stroke-count degradation | F1 to F50 active-path P95 change | | | | |
| Pan/zoom jank | frame P50/P90/P95/P99 and missed frames | | | | |
| Post-edit degradation | repeated write sections around edit sequence | | | | |
| Undo pause | 1 stroke, 500 translate, fragments, 100 undo/redo | | | | |

## Frame distributions

| Build/fixture/action | UI P50/P95/P99 | Raster P50/P95/P99 | Total P50/P95/P99 | missed frames |
|---|---|---|---|---:|
| | | | | |

## Trace attribution

Record evidence for `stylus.dispatch`, `stylus.history.decode`,
`stroke.foreground.update`, `stroke.commit`, `viewport.bake`,
`selection.raycast`, `document.save`, `history.undo`, and `history.redo`.

## Evidence boundary and decision

State which facts are direct measurements, which are derived comparisons, and
which alternatives remain unresolved. Debug data may diagnose but must not be
used as the Profile/Release performance verdict.
