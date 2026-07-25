# M2 readiness and cutover boundary

Status: **pre-M2 physical evidence complete; first Handler cutover allowed**.

This report records the gate immediately before M2 implementation. It accepts
only the Legacy-to-Backend ownership transition, not final product performance.

## Five prerequisite surfaces

1. The fixed `legacy-elements-v1` replay covers create, whole-stroke erase,
   partial erase, selection translation, undo, redo, branch-after-undo,
   cancellation without commit and save/reload at the actual `DocumentBloc`
   event owner.
2. Every step records normalized state, layer order, structural Delta,
   `canUndo`, `canRedo`, and explicitly diagnostic Legacy replay/history
   coordinates.
3. F0 and F50 each have three valid behavior runs. The exact three independent
   F50 performance sessions also combine to `valid=true` through
   `m1_validate_oracle.py`.
4. Frame and owner percentiles use `nearest-rank-v1`; comparison uses the median
   of three per-run percentiles. Rules remain frozen in
   `M1_M2_DECISION_RULES.json`.
5. The retained `devProfile` APK, provenance, JSONL, Perfetto traces, analysis
   JSON and invalid-run evidence remain outside Git under the Windows evidence
   tree.

## Gate checklist

- [x] Static analysis passes on the behavior-affecting application sources.
- [x] Python validator/analyzer suite passes: 13 tests.
- [x] Clean-source `devProfile` APK retained and installed for accepted runs.
- [x] F0 three-run aggregate passes the frozen oracle validator.
- [x] Three independent F50 sessions combine to a valid frozen oracle.
- [x] Three F50 probe runs report zero native and Flutter ring drops.
- [x] Three F50 Perfetto analyses contain all eight required automatic owners
      with zero incomplete slices.
- [x] Real stylus trace contains foreground, commit and save owners.
- [x] WSL, Git mirror and Windows workspace are synchronized.

## Authoritative artifacts

- APK SHA-256:
  `9ad5a78a4f45373b47ed43cf6a53dde3b4aba22cf3e95d2abf2e11ea635301d3`.
- F0 aggregate SHA-256:
  `1d38d7f187a00c9da10240e3c1ea368abcb55a004d61df2c1e848673c547c52a`.
- F50 independent oracle validation SHA-256:
  `515ac69505603b0b563f770e52e75029b22beb5d3580d4397082b409de7eac21`.
- F50 performance baseline SHA-256:
  `261229d6de4cfe67621eea72f94373ef620b0f6fc44d84f5b923b7b6a201a5e3`.
- Manual owner analysis SHA-256:
  `d1cb0bc08075dc24636b07e5e5a51500fff3d2ed665fc57d59755b44c675e298`.

## Owner applicability

`selection.raycast` is not reachable on the empty F0 fixture because there are
no visible renderers. This is an observed producer/input contract, not a
missing fallback. F0 owns empty-state behavior and frame parity; F50 owns the
all-required-owner slice baseline.

## Known current limitations

- The focused current Windows Flutter test is blocked by absent cached
  `pdfium.dll` and a failed dependency TLS download. Earlier 3-test/52-test
  passes are retained history, not current exact-source proof.
- Long F50 bake blocks the main isolate for seconds. Two externally interrupted
  attempts produced focus-event ANRs and are retained as later rendering-risk
  evidence. They are excluded from the accepted same-condition runs.
- Complete product scale curves, optical latency and personalRelease endurance
  are not M2 ownership-boundary inputs.

## Build-log classification

- Font tree-shaking and omission of web-only `pdfrx` assets are expected target
  messages.
- The final Android build completed all native ABIs; there is no current NDK
  build blocker.
- Flutter's Kotlin built-in migration notice remains an upstream/plugin future
  migration warning. It is visible and is not suppressed with an app-side
  workaround.
- Java 8/deprecation messages originate in dependencies and remain visible.

## M2 execution rule

M2 may now proceed one reversible Handler at a time. Each cutover must compare
the same replay and retained baseline. A mismatch must be traced to the first
wrong state/owner; normalization, thresholds and fixture meaning must not be
changed after seeing post-M2 results.
