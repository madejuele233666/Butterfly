# M1 baseline performance report

Status: **host-side oracle/replay path prepared; target-device M2 baseline remains open**.

## Run identity

- Application/build: Notea `devProfile`, package
  `dev.linwood.butterfly.dev.profile`, version 2.5.3 (185).
- Application source/build commit: `7468b4823f7461599bef99b6706b77133abc7336`.
- APK SHA-256: `b9da4a2177ee1a11cfa6c2d834bf4ca26f58d315bc1f5626119b4062f92c19b6`.
- Device: Android-reported `OnePlus OPD2413`, API 36; build fingerprint is in
  `artifacts/m1/M1_DEVICE_REPORT.md`.
- Refresh rate: 120.00001 Hz throughout the retained profile JSONL.
- End snapshot: battery 95%, USB powered, battery 28.9 C, Thermal Status 0,
  high-performance mode 0. This was measured after the run, not at its start.
- Workload: operator-driven continuous handwriting for the 30-second Perfetto
  window, including fast/slow strokes, pressure changes and Pencil key actions.
- Fixture parity: not established. The probe page was used rather than the
  frozen F0/F1/F10/F50 documents.
- Android package manager reports the profile APK as debuggable. Results are a
  profile-AOT diagnostic baseline, not a personalRelease verdict.

## Compared builds

| Build | package/version | configuration parity | retained evidence |
|---|---|---|---|
| Notein | not run | not established | none |
| Butterfly v2.5.3 pristine | not run | not established | none |
| Notea current | `dev.linwood.butterfly.dev.profile` 2.5.3 (185) | standalone exploratory run | JSONL + Perfetto |

## Observed Notea profile measurements

- Native current/history/total samples: 6,407 / 374 / 6,781.
- Flutter PointerEvents: 6,379.
- Native and Flutter ring-buffer drops: 0 / 0.
- 3,307 Flutter FrameTiming records were retained.
- Build p50/p90/p95/p99: 0.233 / 0.335 / 0.439 / 0.917 ms.
- Raster p50/p90/p95/p99: 1.268 / 1.347 / 1.378 / 1.652 ms.
- Total p50/p90/p95/p99: 2.040 / 2.610 / 3.407 / 4.637 ms.

All reported total-frame percentiles are below the nominal 8.33 ms period at
120 Hz for this workload. This does not measure contact-to-visible-ink latency,
does not cover a real document fixture and does not prove missed-frame count.

## Perfetto attribution

- Trace size: 67,013,554 bytes.
- Perfetto version recorded in the trace: v49.0; the trace was parsed with the
  official trace processor distributed by the Perfetto Python package.
- `stylus.dispatch`: 1,591 slices, average 0.416 ms, maximum 1.753 ms.
- `stylus.history.decode`: 1,668 slices, average 0.261 ms, maximum 1.464 ms.
- Both slice types resolve through slice -> thread_track -> thread -> process to
  PID 20780, main thread name `fly.dev.profile`.
- All threads in PID 20780 accumulated 3,842.231 ms scheduled CPU time across
  8,966 sched slices during the trace.
- The trace schema contains Android actual/expected FrameTimeline tables, but
  `actual_frame_timeline_slice` contained no rows. No Android jank count is
  claimed from this trace.
- Stroke/bake/raycast/save/undo/redo slices were not observed because the probe
  page workload did not enter those application owners.

## Six performance red lines

| Red line | Current evidence | Status |
|---|---|---|
| Visible ink lag | No 240/480 fps external camera capture | open |
| Sample loss/distortion | Probe rings dropped zero; native/Flutter counts retained, but OS/optical loss not proven | partial |
| Stroke-count degradation | F1/F10/F50 active-path comparison not run | open |
| Pan/zoom jank | Mixed-refresh input evidence exists; formal fixture replay and Android FrameTimeline absent | open |
| Post-edit degradation | Edit sequence and post-edit writing not run | open |
| Undo pause | Fixed 100 undo/redo sequence not run | open |

## Retained evidence

- `D:\files\Notea_Mirror\evidence\m1\m1-2026-07-24T19-36-57.656978Z-profile.jsonl`
  (`8abd35228608381ad957efd2b00fb91cd5e8ec41722e92d18b5784925bfa54ff`)
- `D:\files\Notea_Mirror\evidence\m1\m1-dev-profile-analysis.json`
- `D:\files\Notea_Mirror\evidence\m1\notea-m1-dev-profile.perfetto-trace`
  (`e302cd173abe96f8a7f35f06e9d19b49d34da406f93c0550227b4b9b5d949f5c`)

## Decision

The current instrumentation is capable of quantifying native dispatch/history
cost and Flutter frame distributions on the real device. Because this run used
the probe page, it did not enter the document owners and cannot authorize the
first M2 Handler cutover.

The remaining M2 gate is narrower and causal: freeze the Legacy operation
oracle and deterministic owner-boundary replay, run it on an empty and a
representative stress document at least three times in `devProfile`, observe
the applicable stroke/bake/raycast/save/history traces, and freeze the parity
and regression rules before post-M2 data exists.

Notein/pristine/current comparison, the full scale curve, personalRelease
endurance and optical latency remain useful later evidence, but do not block
M2 because the backend interface does not own those product or active-rendering
claims.

## Prepared after the exploratory run

- Shared deterministic fixture producer is used by both the command-line
  generator and the in-app baseline route.
- `/debug/m1-baseline/F0` and `/debug/m1-baseline/F50` create a fresh real
  document canvas for each requested run and execute `legacy-elements-v1`.
- The oracle records an exact normalized state hash, layer order,
  created/updated/removed payloads, observed history position and undo/redo
  capability after every step. Its sequence revision and history position are
  explicitly diagnostic Legacy observations, not invented production fields.
- Cancellation asserts that no stable `DocumentEvent` is emitted; save/reload
  compares the normalized state after `saveBytes` and `NoteData.fromData`.
- `artifacts/m1/M1_M2_DECISION_RULES.json` freezes behavior equality, run
  validity and M2-only performance thresholds before post-M2 results exist.
- `scripts/m1_validate_oracle.py` rejects missing, reordered or divergent
  three-run sessions.

No target-device F0/F50 session has been run yet. This preparation does not
change the report's physical evidence boundary and does not authorize the first
Handler cutover until both retained sessions pass.
