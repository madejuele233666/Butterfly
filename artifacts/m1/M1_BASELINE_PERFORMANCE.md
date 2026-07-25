# M1 baseline performance report

Status: **M1-to-M2 ownership-cutover input is complete; this is not a product-release performance PASS**.

## Run identity

- Application/build: Notea `devProfile`, package
  `dev.linwood.butterfly.dev.profile`, version 2.5.3 (185).
- Physically tested APK source anchor:
  `6411de344427dfd59eff1186fd13d81bc3dbb1b8`.
- APK SHA-256:
  `9ad5a78a4f45373b47ed43cf6a53dde3b4aba22cf3e95d2abf2e11ea635301d3`.
- Device: Android-reported `OnePlus OPD2413`, API 36, serial `5370fdbb`;
  full fingerprint is retained in `M1_DEVICE_REPORT.md`.
- Requested and active baseline refresh: 120.00001 Hz.
- End-state observations: USB powered, battery 100%, battery temperature 29.0 C,
  Thermal Status 0. The vendor thermal-service CPU values were internally
  inconsistent and are not used as acceptance evidence.
- Percentiles use `nearest-rank-v1`. The comparison statistic is the median of
  three independent per-run percentiles, exactly as frozen in
  `M1_M2_DECISION_RULES.json`.

The APK source anchor predates later trace-analysis scripts and documentation
only. Those later changes do not alter application bytecode. The retained APK
itself is the package installed for every accepted physical run.

## Behavior baseline

- F0 accepted three-run aggregate:
  `baseline\m1-baseline-f0-2026-07-25T13-21-14.012310Z.json`, SHA-256
  `1d38d7f187a00c9da10240e3c1ea368abcb55a004d61df2c1e848673c547c52a`.
- F0 fixture hash: `edaac01263bba468`.
- F50 independent performance sessions were combined through the existing
  oracle validator. `f50-independent-oracle-validation.json` reports three
  runs, `valid=true`, no errors; SHA-256
  `515ac69505603b0b563f770e52e75029b22beb5d3580d4397082b409de7eac21`.
- F50 fixture hash: `350912cceb29e6af`.
- Replay: `legacy-elements-v1`; normalization:
  `element-json-f64-1e-6-v1`; rules:
  `m1-m2-gate-2026-07-25-v1`.

Both fixtures preserve the frozen 13-step state, history and Delta contract.
The independent F50 runs also prove that the exact performance sessions, not
only an earlier aggregate, are behavior-identical.

## F50 performance baseline

The authoritative artifact is
`D:\files\Notea_Mirror\evidence\m1\f50-independent-performance-baseline.json`
(SHA-256
`261229d6de4cfe67621eea72f94373ef620b0f6fc44d84f5b923b7b6a201a5e3`).
Each run was a fresh cold-start `Runs=1` session with its own Perfetto trace and
probe JSONL. All three owner analyses contain every required owner, zero
incomplete slices, and all probe rings report zero drops.

### Frame medians, microseconds

| Metric | P50 | P95 | P99 |
|---|---:|---:|---:|
| Build | 98,210 | 233,579 | 233,579 |
| Raster | 105,710 | 200,110 | 200,110 |
| Total | 456,066 | 8,312,691 | 8,312,691 |

These values include the deliberately heavy F50 replay, normalization and
render-owner work. They are comparison baselines for the M2 ownership change,
not interactive-frame acceptance thresholds.

### Owner-slice P95 medians, microseconds

| Owner | P95 |
|---|---:|
| `m1.oracle.create-stroke` | 144.844 |
| `m1.oracle.erase-strokes` | 209.896 |
| `m1.oracle.partial-erase` | 204.115 |
| `m1.oracle.translate-selection` | 198.750 |
| `history.undo` | 270.990 |
| `history.redo` | 188.646 |
| `selection.raycast` | 279,406.250 |
| `viewport.bake` | 12,294,791.662 |

The high F50 raycast and bake values are observed Legacy behavior and are not
hidden or reclassified. M2 must not regress them beyond the frozen rule; later
rendering stages decide whether they require architectural replacement.

## F0 applicability boundary

F0 already has a valid three-run behavior and frame baseline. A retained
30-second applicability trace proves that all automatic owners except
`selection.raycast` are observed. The missing raycast is contractually
unreachable: an empty fixture has no visible renderer, and
`DocumentBloc.rayCastRect` returns before entering the raycast algorithm.
Artificially creating work would stop measuring F0. Therefore owner-slice
regression uses F50, where all eight owners are reachable; F0 remains the empty
state/parity/frame fixture.

Evidence:
`final-f0-owner-applicability-analysis.json`, SHA-256
`68fd357577cc5904d34b4ebaeb23e87cbfae3fc8abb1e8e43b29ce2537d03fc1`.

## Manual real-stroke owners

The separate stylus session retains 560 completed
`stroke.foreground.update`, two `stroke.commit`, and five `document.save`
slices. Its analysis SHA-256 is
`d1cb0bc08075dc24636b07e5e5a51500fff3d2ed665fc57d59755b44c675e298`.
This proves real input reaches those owners; it is not mixed into deterministic
F50 owner regression.

## Invalid evidence retained but excluded

- `m1-baseline-f50-2026-07-25T13-01-13.057987Z.json` was interrupted while
  being written and is invalid JSON.
- The 360-second/64-MiB trace overwrote early runs in its ring buffer.
- `notea-m1-f50-full3-8594b8e-240s-invalid-anr.perfetto-trace` ended after a
  focus-event ANR.
- `notea-m1-f50-run3-96db167-100s-invalid-external-focus-anr.perfetto-trace`
  coincided with a WeChat VoIP foreground transition; Android killed the app
  after `FocusEvent(hasFocus=false)` waited five seconds behind a long bake.

These files are retained as causal evidence and are not counted toward the
accepted three runs. The focus-event ANR is a real reachable Legacy risk for
later rendering work, but an externally interrupted run cannot define the M2
same-condition baseline.

## Tool and test boundary

- Windows `flutter analyze --no-pub`: passed with zero issues on the
  behavior-affecting application sources.
- Current Python analyzer/validator suite: 13 tests passed.
- The final clean Windows Android build rebuilt all Cargokit ABIs and produced
  the retained APK hash.
- A current focused Windows Flutter-test rerun is blocked by the missing local
  `pdfium.dll`; the dependency attempted a TLS download after cache cleanup.
  Earlier focused/full Flutter passes are historical and are not presented as
  current-source test proof.
- The device-side three-run oracle and owner traces are current behavioral
  evidence for the M1-to-M2 gate.

## Decision

The first M2 Handler ownership cutover is authorized. Post-M2 runs must use the
same APK mode, fixtures, replay, normalization, percentile implementation and
three-independent-run aggregation, then apply the frozen behavior and
regression rules without changing ignore fields or thresholds.

This decision does not accept optical ink latency, long-duration release use,
full capacity curves, exact Pencil shortcut semantics, Jetpack Ink, or tile
cache. Those remain attached to their actual later owners and decision gates.
