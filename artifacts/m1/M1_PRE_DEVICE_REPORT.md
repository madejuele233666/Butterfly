# M1 pre-device readiness report

Status: **implementation in progress; physical evidence intentionally absent**.

## Acceptance boundary

This report covers everything that can be prepared before the OPPO Pencil 2
action matrix begins. It must not be changed to M1 PASS until the device
capability JSON, Butterfly/Notein performance comparison, Perfetto trace and
external high-speed-video evidence exist.

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

## Pre-device gate

- [ ] Dart formatting and static analysis pass
- [ ] Flutter tests pass, including ring-buffer ownership tests
- [ ] Deterministic fixtures generate with a retained manifest
- [ ] `devDebug` APK builds with probe enabled
- [ ] `devProfile` APK builds and is profileable
- [ ] `personalRelease` APK builds with probe disabled
- [ ] APK package IDs and checksums are retained
- [ ] Windows build/test evidence is retained outside Git

## Physical work deliberately left open

- [ ] 60 Hz and 120 Hz Pencil 2 action matrices
- [ ] Device capability JSON populated from ordinary-app observations
- [ ] Native/history/Flutter sample accounting
- [ ] Notein versus pristine Butterfly versus current Profile baselines
- [ ] Perfetto trace captured on the target tablet
- [ ] 240/480 fps optical latency recordings and analysis
