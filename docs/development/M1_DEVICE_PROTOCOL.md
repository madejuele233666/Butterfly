# M1 device and performance protocol

This protocol begins only after `scripts/windows-m1.ps1 prepare-all` succeeds.
It does not treat Debug results as performance evidence.

## Builds and package isolation

| Gradle variant | package | probe | purpose |
|---|---|---:|---|
| `devDebug` | `dev.linwood.butterfly.dev.debug` | on | Pencil/event semantics and interaction debugging |
| `devProfile` | `dev.linwood.butterfly.dev.profile` | on | Flutter/Perfetto frame and native hotspot measurement |
| `personalRelease` | `dev.linwood.butterfly.personal` | off | final experience and long-duration use |

The original production release remains `dev.linwood.butterfly`. Each M1
variant therefore has a separate Android data directory.

## Input capability run

1. Install `notea-m1-dev-debug.apk` over USB and launch the probe:
   `powershell -File scripts/windows-m1.ps1 start-probe -Device <serial>`.
2. Open `/debug/m1`, reset, start, and execute the full action matrix once to
   establish observable fields. Request 60 Hz and 120 Hz separately, but record
   the refresh rate reported by every event; retain an OS-forced transition as
   mixed-refresh evidence instead of claiming a pure run.
3. Stop and export once. Do not enable per-event Logcat.
4. Pull the JSONL with the `pull-probe` action.
5. Run `python scripts/m1_analyze_probe.py <run.jsonl> -o <summary.json>`.
6. Compare Android current+historical samples with Flutter PointerEvents.
   Every difference needs an explicit producer/consumer explanation.
7. Fill `artifacts/m1/DEVICE_CAPABILITIES_OPPO_PAD4PRO.template.json` from the
   retained data. Promise press/hold/release behavior only if the ordinary app
   observes those distinct events.

Split actions into individually labelled traces only when shortcut or palm
semantics are about to enter implementation. A consolidated trace proves event
observability, not which action produced an ambiguous key pair or CANCEL.

## M2 ownership-cutover baseline

Before the first Handler is changed to emit a Command, freeze a deterministic
Legacy oracle for CreateStroke, EraseStrokes, PartialErase,
TranslateSelection, Undo, Redo, cancellation without commit, and save/reload.
Record normalized document state, history cursor, revision and Delta sets after
every step. Drive the replay at the owner boundary; manual input is only an
interaction smoke test.

Run the same versioned replay at least three times on an empty document and one
representative stress fixture in `devProfile`. It must enter the real document
canvas and fire the applicable `stroke.commit`, `stroke.foreground.update`,
`viewport.bake`, `selection.raycast`, `document.save`, `history.undo`, and
`history.redo` owner traces. Freeze equality and performance-regression rules
before collecting post-M2 data.

### Prepared execution path

On Windows, first complete all host-side gates and build the exact Profile APK:

```powershell
Set-Location D:\files\Notea_Mirror\workspace
.\scripts\windows-m1.ps1 -Action prepare-m2-baseline
```

This runs analysis, the focused Legacy oracle tests, deterministic fixture
generation and the `devProfile` build. The device phase then consists of two
three-run sessions:

```powershell
.\scripts\windows-m1.ps1 -Action start-baseline -Device <serial> -Fixture F0 -Runs 3
.\scripts\windows-m1.ps1 -Action pull-baseline -Device <serial> -Runs 3
python scripts\m1_validate_oracle.py `
  D:\files\Notea_Mirror\evidence\m1\baseline\<f0-session>.json

.\scripts\windows-m1.ps1 -Action start-baseline -Device <serial> -Fixture F50 -Runs 3
.\scripts\windows-m1.ps1 -Action pull-baseline -Device <serial> -Runs 3
python scripts\m1_validate_oracle.py `
  D:\files\Notea_Mirror\evidence\m1\baseline\<f50-session>.json
```

`start-baseline` installs the retained Profile APK, creates a fresh fixture for
every run, opens the real document canvas and automatically executes the
versioned Legacy replay. It writes one aggregate oracle JSON plus one
Pointer/Frame JSONL per run. The only authority for equality and regression is
`artifacts/m1/M1_M2_DECISION_RULES.json`; changing it requires a superseding ADR
before affected post-M2 data is collected.

Run Perfetto from a second PowerShell before invoking `start-baseline`, so the
automatic replay is inside the trace window. The automated path exercises
Legacy element events, undo/redo, raycast and bake. On a separate clean F0
Profile session, manually write one stroke and save once to observe
`stroke.foreground.update`, `stroke.commit` and `document.save`; these manual
owner traces are presence/performance evidence, not the deterministic behavior
oracle.

## Extended product and decision-gate baseline

Use the same fixture, refresh mode, brightness, power/performance mode, battery
range, and thermal starting state for every comparison. Disable Android Studio
mirroring, scrcpy, screen recording, Layout Inspector, high-frequency Logcat,
and unrelated background apps.

When M4 release readiness, M7 active ink, or M8 stable rendering actually needs
the broader evidence, expand to F0/F1/F10/F50 and the same versioned path. Retain:

- Flutter frame P50/P90/P95/P99 and missed-frame count;
- UI/build, raster, and platform-composition attribution;
- `viewport.bake`, `selection.raycast`, `document.save`, and history traces;
- device build fingerprint, refresh rate, temperature, battery and run mode.

Capture Perfetto with `scripts/windows-m1.ps1 perfetto -Device <serial>` while
the `devProfile` build is foregrounded.

Notein/pristine/current three-way comparison, the full scale curve,
personalRelease endurance and optical video are not M2 prerequisites unless M2
changes the owner they measure.

## 240/480 fps external-camera protocol

The camera must show both the physical pen tip and the changing screen pixels.
Lock camera position, exposure, focus, frame rate and shutter; place a visible
frame/time marker in view. Use the same device orientation, refresh mode, brush,
zoom, stroke path and operator cadence for Notein, pristine Butterfly, and the
current build. Record contact-to-first-pixel, maximum moving gap, and lift-tail
settling in video frames, then convert using the measured camera frame rate.

An external video measures the optical end-to-end path. Flutter frame timings
or touch timestamps cannot substitute for it. This is required to decide an
end-to-end active-ink latency claim at M7 or release, not to introduce the M2
backend interface.
