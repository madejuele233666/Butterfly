# M1 physical device report

Status: **partial physical evidence; M1 is not yet complete**.

## Device identity

- ADB serial: `5370fdbb`.
- Android reports manufacturer `OnePlus`, model `OPD2413`, API 36.
- Build fingerprint: `OnePlus/OPD2413/OP615EL1:16/AP3A.240617.008/V.4190afa-2071901-2076419:user/release-keys`.
- The exact retail product name was not exposed by the inspected properties.
  The expected OPPO Pad 4 Pro identity is therefore not treated as verified.
- The internal display reports 2400 x 3392 and supports 30/48/50/60/90/120/144 Hz modes.

## Application and isolation

- `dev.linwood.butterfly.dev.debug` version 2.5.3 (185) was installed without
  replacing `dev.linwood.butterfly`.
- `/debug/m1` was the top-resumed activity and the probe channel started without
  a crash or `MissingPluginException`.
- The input run used the APK whose SHA-256 is retained in
  `artifacts/m1/apk-checksums.sha256`.

## 120 Hz action matrix

- Session: `m1-2026-07-24T19-25-47.642796Z`.
- All 9,871 native motion events reported 120.00001 Hz.
- Native current/history/total samples: 9,871 / 2,674 / 12,545.
- Flutter pointer events: 9,750.
- Native and Flutter ring-buffer drops: 0 / 0.
- Pressure covered 0.0 to 1.0. Tilt varied from 0.0 to 0.634966 rad and
  orientation varied from -1.570796 to 2.912979 rad.
- Hover enter/move/exit and distance 1 were observed from `touchpanel_pen`.
- `OnePlus Pencil` emitted keyCode 334 / scanCode 191: 15 down records, four up
  records and 11 repeat records, with maximum repeatCount 11.
- One ACTION_CANCEL was observed.

Native total samples and Flutter PointerEvents are not a one-to-one contract:
the native total includes 2,674 historical samples and the Android stream also
retains hover enter/exit actions. Zero ring drops proves only that the two probe
buffers did not overflow; it does not prove optical or OS-level zero loss.

## Requested 60 Hz action matrix

- Session: `m1-2026-07-24T19-33-03.942075Z`.
- Before starting, system `peak_refresh_rate` and `min_refresh_rate` were set to
  60.0 and DisplayManager reported active mode 5 at 60.000004 Hz.
- 14,258 native events remained at 60.000004 Hz.
- At native event 14,259, the first touchscreen ACTION_DOWN of the two-finger
  sequence reported 120.00001 Hz. The remaining 1,027 events stayed at 120 Hz.
- The settings database still contained 60.0 / 60.0 while DisplayManager active
  mode had changed to 120 Hz. Standard settings therefore did not constrain the
  two-finger scenario to 60 Hz.
- Native current/history/total samples: 15,318 / 4,619 / 19,937; Flutter pointer
  events: 15,168; both probe drops were zero.
- The original refresh settings (`peak=120.00001`, absent `min`) were restored
  and verified after the run.

This run is retained as mixed-refresh evidence. It must not be described as a
pure 60 Hz full matrix.

## Capability decision

Ordinary Android application APIs expose current and historical stylus samples,
pressure, tilt, orientation, hover, cancel events and a separate Pencil
KeyEvent endpoint. Root is not justified for the first-pass capability probe.

The consolidated action run does not label individual events with action-matrix
step identity. It therefore does not prove which key pair means hover press,
contact press or double-tap, nor which CANCEL belongs to each palm ordering.
Those claims require isolated per-action traces.

## Retained evidence

- `D:\files\Notea_Mirror\evidence\m1\m1-2026-07-24T19-25-47.642796Z.jsonl`
  (`baf9ab2b613687786d44cf5d4588920921bd4bc07beffb13a6fca7eb687245c2`)
- `D:\files\Notea_Mirror\evidence\m1\m1-120hz-analysis.json`
- `D:\files\Notea_Mirror\evidence\m1\m1-2026-07-24T19-33-03.942075Z.jsonl`
  (`609a5af09a656b1617e263b05000fa5ed84ee8cda3cf1fadfe07529fe3a046b4`)
- `D:\files\Notea_Mirror\evidence\m1\m1-60hz-attempt-analysis.json`
- `D:\files\Notea_Mirror\evidence\m1\device-5370fdbb\` screenshots.

## Remaining M1-A gate

- Isolate the 12 action-matrix steps into separately labelled runs when exact
  shortcut and palm-sequence semantics are required.
- Capture a stable device-info snapshot artifact rather than relying only on
  the retained JSONL session header and this report.
- Wi-Fi ADB is optional for daily development and was not verified in this USB
  capability run.
