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
2. Open `/debug/m1`, reset, start, and execute all twelve actions shown on the
   page. Do one run at 60 Hz and one at 120 Hz.
3. Stop and export once. Do not enable per-event Logcat.
4. Pull the JSONL with the `pull-probe` action.
5. Run `python scripts/m1_analyze_probe.py <run.jsonl> -o <summary.json>`.
6. Compare Android current+historical samples with Flutter PointerEvents.
   Every difference needs an explicit producer/consumer explanation.
7. Fill `artifacts/m1/DEVICE_CAPABILITIES_OPPO_PAD4PRO.template.json` from the
   retained data. Promise press/hold/release behavior only if the ordinary app
   observes those distinct events.

## Profile and Perfetto run

Use the same fixture, refresh mode, brightness, power/performance mode, battery
range, and thermal starting state for every comparison. Disable Android Studio
mirroring, scrcpy, screen recording, Layout Inspector, high-frequency Logcat,
and unrelated background apps.

For each F0/F1/F10/F50 fixture, replay the same 10-second input path and retain:

- Flutter frame P50/P90/P95/P99 and missed-frame count;
- UI/build, raster, and platform-composition attribution;
- `viewport.bake`, `selection.raycast`, `document.save`, and history traces;
- device build fingerprint, refresh rate, temperature, battery and run mode.

Capture Perfetto with `scripts/windows-m1.ps1 perfetto -Device <serial>` while
the `devProfile` build is foregrounded.

## 240/480 fps external-camera protocol

The camera must show both the physical pen tip and the changing screen pixels.
Lock camera position, exposure, focus, frame rate and shutter; place a visible
frame/time marker in view. Use the same device orientation, refresh mode, brush,
zoom, stroke path and operator cadence for Notein, pristine Butterfly, and the
current build. Record contact-to-first-pixel, maximum moving gap, and lift-tail
settling in video frames, then convert using the measured camera frame rate.

An external video measures the optical end-to-end path. Flutter frame timings
or touch timestamps cannot substitute for it.
