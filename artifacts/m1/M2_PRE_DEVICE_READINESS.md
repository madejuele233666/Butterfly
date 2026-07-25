# M2 pre-device readiness

Status: **host preparation implemented; target-device evidence remains open**.

This report is the boundary immediately before the two physical `devProfile`
baseline sessions. It does not authorize a Handler cutover and it is not a
device PASS report.

## Five prerequisite surfaces

1. The Legacy behavior oracle replays the fixed 13-step
   `legacy-elements-v1` sequence at the actual `DocumentBloc` event owner. It
   covers create, whole-stroke erase, partial erase, selection translation,
   undo, redo, branch-after-undo, cancellation without commit, and save/reload.
2. Every step records the normalized document hash, layer order, structural
   Delta, `canUndo`, and `canRedo`. `sequenceRevision` and `historyPosition`
   are explicitly diagnostic replay coordinates because Legacy exposes no
   production revision or public history cursor.
3. The in-app baseline route creates a fresh F0 or F50 fixture for each run,
   enters the real document canvas, and requests three runs by default.
4. Behavior equality, run validity, frame regression, and owner-slice
   regression are frozen in `M1_M2_DECISION_RULES.json`. Oracle normalization,
   fixture construction, and JSON export are excluded from timed owner slices.
5. Windows preparation retains analysis, focused tests, fixture manifests,
   build logs, the Profile APK, and APK provenance outside Git. The provenance
   records a clean source commit and the copied APK SHA-256.

## Host proof required before device work

- [x] Dart formatting and repository diff checks pass.
- [x] Flutter static analysis passes with the locked dependency set.
- [x] Focused Legacy oracle tests pass.
- [x] Full Flutter tests pass.
- [x] Python oracle-validator tests and bytecode compilation pass.
- [x] All deterministic fixtures are regenerated with a manifest.
- [x] A clean-source `devProfile` APK and provenance JSON are retained.
- [x] WSL, Git mirror, Windows workspace, and GitHub branch resolve to the same
      commit.

Evidence snapshot on 2026-07-25:

- Windows `flutter analyze --no-pub`: no issues found.
- Windows focused Legacy oracle suite: 3 tests passed.
- Windows full Flutter suite: 52 tests passed on the formatted sources.
- WSL Python suites: 5 tests passed; validator/analyzer bytecode compiled.
- Profile APK provenance source: `2e39a1595d44b38db3f2a71f3b8adf75f6c78c15`
  with a clean Windows worktree. This source includes the final Dart formatter
  output and the completed host-readiness record.
- Profile APK SHA-256:
  `d900674dca0acaefa3d4fd99778d3b79bc7c19bb3899cd39b2d2cc762070f99b`.

## Physical evidence deliberately left open

- [ ] F0 aggregate contains three valid, structurally identical oracle runs.
- [ ] F50 aggregate contains three valid, structurally identical oracle runs.
- [ ] Corresponding Pointer/Frame JSONL and Perfetto traces are retained.
- [ ] Automatic bake/raycast/history owner traces are present.
- [ ] A separate clean F0 manual session observes foreground, commit, and save
      owner traces.
- [ ] The retained sessions pass `scripts/m1_validate_oracle.py` and the frozen
      performance rules.

Only the unchecked physical evidence can close the M1-to-M2 gate. Host tests,
an APK build, or earlier probe-page traces cannot substitute for it.

## Build-log classification

- Font tree-shaking and omission of web-only `pdfrx` assets are expected target
  optimization messages, not missing Android content.
- The Android toolchain currently builds successfully with command-line tools
  22.0, AGP 8.13.2, Gradle 8.14.5, and compile SDK 36. An SDK XML compatibility
  warning appeared in an earlier build but did not reproduce in the retained
  final build; no current failure is hidden or claimed fixed without a stable
  trigger.
- Flutter reports that several plugins still apply the Kotlin Gradle Plugin.
  This is an upstream/plugin migration warning for a future Flutter version.
  It remains visible rather than being hidden or worked around in the app.
