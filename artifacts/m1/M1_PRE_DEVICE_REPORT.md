# M1 pre-device readiness report

Status: **historical pre-device gate; physical work has started**.

Current physical evidence and remaining gates are recorded in
`artifacts/m1/M1_DEVICE_REPORT.md` and
`artifacts/m1/M1_BASELINE_PERFORMANCE.md`. This file remains the record of the
pre-device readiness boundary and is not an M1 PASS report.

## Acceptance boundary

This report covers everything that was prepared before the OPPO Pencil 2
action matrix began. Its original all-in-one acceptance boundary has been
superseded by the owner-specific gate in
`docs/ANDROID_NOTE_EXECUTION_PLAN_V1_1_0/09_DECISION_GATES/M1_TO_M2_GATE.md`.
This historical file is not an M1 PASS report: current input and performance
status lives in the two reports linked above.

## Prepared surfaces

- Android Activity boundary captures touch, generic motion and key events.
- Every MotionEvent retains current points plus all historical samples, device
  identity, buttons/actions, axes and current refresh rate.
- Android and Flutter collectors use bounded in-memory rings and report drops.
- Export is explicit, chunked across the platform channel, and written once as
  JSONL after an action run.
- Flutter captures PointerEvent facts and build/raster/total FrameTiming.
- Stable trace names exist for current owners and future Rust/SQLite boundaries.
- `devDebug`, `devProfile` and `personalRelease` have isolated application IDs;
  the probe is compile-time disabled in personal release.
- Deterministic F0/F1/F10/F50/F200/FLONG/FFRAG/FPAGE generation is available.
- Perfetto and 240/480 fps external-camera protocols are frozen.
- `scripts/m1_analyze_probe.py` converts retained JSONL into sample, axis,
  button, loss and frame-distribution observations without assigning shortcut
  semantics that the action matrix has not proven.

## Verified pre-device evidence

- Application source/build commit: `7468b4823f7461599bef99b6706b77133abc7336`.
- `flutter analyze --no-pub`: no issues found. Evidence:
  `D:\files\Notea_Mirror\evidence\m1\flutter-analyze.log`.
- `flutter test --no-pub`: 49 tests passed. Evidence:
  `D:\files\Notea_Mirror\evidence\m1\flutter-test.log`.
- Probe analyzer: two Python owner-boundary tests passed; Python bytecode
  compilation passed.
- All eight fixtures generated twice with identical SHA-256 values. The primary
  manifest is `D:\files\Notea_Mirror\evidence\m1\fixtures\manifest.json`.
- Final APKs and logs are under `D:\files\Notea_Mirror\evidence\m1`; hashes are
  frozen in `artifacts/m1/apk-checksums.sha256`.
- APK analyzer reports package IDs `dev.linwood.butterfly.dev.debug`,
  `dev.linwood.butterfly.dev.profile`, and `dev.linwood.butterfly.personal`.
- Generated BuildConfig reports M1 probe `true`, `true`, and `false`
  respectively. The profile manifest contains `<profileable
  android:shell="true" />`; personal release contains `android:shell="false"`.
- APK DEX inspection confirms `StylusProbePlugin` and its capture/channel methods
  are present in `devDebug`.

## Pre-device gate

- [x] Dart formatting and static analysis pass
- [x] Flutter tests pass, including ring-buffer ownership tests
- [x] Deterministic fixtures generate with a retained manifest
- [x] `devDebug` APK builds with probe enabled
- [x] `devProfile` APK builds and is profileable
- [x] `personalRelease` APK builds with probe disabled
- [x] APK package IDs and checksums are retained
- [x] Windows build/test evidence is retained outside Git

## Physical work deliberately left open

- [ ] 60 Hz and 120 Hz Pencil 2 action matrices
- [ ] Device capability JSON populated from ordinary-app observations
- [ ] Native/history/Flutter sample accounting
- [ ] Notein versus pristine Butterfly versus current Profile baselines
- [ ] Perfetto trace captured on the target tablet
- [ ] 240/480 fps optical latency recordings and analysis

The unchecked three-way comparison and optical recordings are later product,
M7 or M8 evidence rather than prerequisites for the M2 backend ownership
change. The authoritative remaining M2 items are the Legacy oracle,
owner-boundary replay and two-fixture three-run document-canvas Profile
baseline.
