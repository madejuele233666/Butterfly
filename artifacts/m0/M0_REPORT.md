# M0 verification report

Captured on 2026-07-24 (Asia/Tokyo).

## Verdict

The reproducible software baseline, AVD acceptance, and connected physical
device acceptance are complete. The M0 exit gate is **PASS**. Windows ADB sees
authorized serial `5370fdbb`; the corrected release APK installed, cold-started,
remained in the foreground, rendered the Butterfly home screen, and produced no
app-scoped fatal or plugin-registration error in the captured launch log.

## Immutable baseline

- Official Butterfly tag `v2.5.3`, local pristine branch, initial instrumented
  branch, local mirror refs, and fork refs all resolve to
  `a10a9787fd4fdc51c9426ead83ff063136015fb2`.
- `git diff v2.5.3^{commit} baseline/v2.5.3-pristine` is empty.
- Fork: `https://github.com/madejuele233666/Butterfly`.
- Working development branch: `work/v1-main`; product behavior was not changed
  for M0.
- Requirements, decision freeze, source ledger, Pub lock, and Gradle wrapper
  hashes are frozen in `toolchain-lock.env`.

## Windows/WSL ownership and synchronization

- WSL source of truth: `/home/madejuele/projects/Notea`.
- Bare Git relay: `D:\files\Notea_Mirror\git\Notea.git`.
- Windows build/test clone: `D:\files\Notea_Mirror\workspace`.
- Windows evidence and APK store: `D:\files\Notea_Mirror\evidence`.
- `scripts/sync-code.sh` and `scripts/sync-code.ps1` exchange committed Git
  objects only. They require a clean tree, fast-forward only, and verify the
  pristine baseline commit. Toolchains, caches, build outputs, secrets, AVD
  data, and evidence are not directory-synchronized.

## Toolchain and host checks

- `flutter doctor -v`: no issues found; Flutter 3.44.1, Dart 3.12.1, Android
  SDK/API 36, Build Tools 36.0.0, Java 21, accepted licenses.
- WHPX 10.0.26100: installed and usable.
- Android Studio, SDK, emulator, NDK, CMake, Flutter, and the AVD are stored on
  `D:` under `D:\files\Notea_Mirror`.
- Rust stable has Android armv7, arm64, i686, and x86_64 targets installed.
- Kotlin incremental compilation is disabled in the Windows user Gradle
  configuration because its cache path converter cannot relativize plugin
  sources on `C:` against the Android build on `D:`. This changes build caching,
  not application behavior.
- Cargo Git dependencies use Git CLI and GitHub SSH on port 443. The build is
  therefore independent of the broken direct GitHub HTTPS handshake path.

## Android warning remediation

- The application NDK is pinned to installed revision `29.0.14206865`, which is
  newer than the highest plugin requirement (`29.0.13846066`). The previous NDK
  mismatch warning is absent from the rebuilt release log.
- The application no longer applies `kotlin-android` directly and retains its
  Kotlin compiler target through the `kotlin.compilerOptions` DSL, following
  Flutter's application migration contract. The previous app-owned KGP warning
  is absent.
- `cupertino_icons 1.0.9` is now a locked direct dependency. The previous
  missing-font-family warning is absent, and `CupertinoIcons.ttf` is included
  and tree-shaken normally.
- A separate future-compatibility warning remains for eight dependency-owned
  Android plugins. Their currently selected versions and the newest hosted
  versions available on 2026-07-24 still apply KGP in their own Gradle files.
  This is an upstream plugin migration blocker, not an application setting that
  can be correctly hidden or compensated for locally.

## Tests and APKs

- After explicit `flutter pub get`, `flutter test --no-pub`: 47 tests passed.
  Evidence:
  `D:\files\Notea_Mirror\evidence\flutter-test-20260724-213312.log`.
- Official universal Android APK downloaded from the v2.5.3 GitHub release;
  its SHA-256 matches the upstream `checksums.txt` entry.
- Local production debug, profile, and release APKs built successfully from the
  worktree whose Butterfly product source is based on the exact v2.5.3 tag.
- All local APKs contain `armeabi-v7a`, `arm64-v8a`, and `x86_64`, including
  `libpdfium.so` and `libsuper_native_extensions.so` for each ABI.
- Stable artifact paths and SHA-256 values are listed in
  `artifacts/m0/apk-checksums.sha256`.

Build evidence:

- Debug: `D:\files\Notea_Mirror\evidence\flutter-build-debug-20260724-201853.log`
- Profile: `D:\files\Notea_Mirror\evidence\flutter-build-profile-20260724-203233.log`
- Release: `D:\files\Notea_Mirror\evidence\flutter-build-release-20260724-202255.log`
- Corrected release: `D:\files\Notea_Mirror\evidence\flutter-build-release-20260724-212848.log`

## AVD acceptance

- AVD: `NoteDev_API36_Tablet`, Android 16/API 36 AOSP x86_64, WHPX.
- Release APK installed successfully on `emulator-5554`.
- Cold launch returned `Status: ok`; process `dev.linwood.butterfly` remained
  alive and `MainActivity` was the top resumed activity.
- The earlier missing `libsuper_native_extensions.so` plugin registration error
  disappeared after Cargo's Git transport was fixed and the APK was rebuilt.
- Current app-scoped error log contains only the expected release/debugger and
  Android ashmem deprecation messages; no plugin registration or fatal crash.
- Screenshot:
  `D:\files\Notea_Mirror\evidence\notea-m0-release-pass-20260724.png`.

## Physical device acceptance

- ADB serial: `5370fdbb`; reported manufacturer `OnePlus`, model `OPD2413`,
  Android 16/API 36, physical size `2400x3392`. The device exposes OPlus system
  components, but no retail market name was reported, so the evidence does not
  infer a more specific product name.
- Corrected production release installation returned `Success`; package manager
  reports `versionName=2.5.3`, `versionCode=185`, `targetSdk=36`, and primary ABI
  `arm64-v8a`.
- Recorded cold launch returned `Status: ok`, `LaunchState: COLD`, and
  `Activity: dev.linwood.butterfly/.MainActivity`; `TotalTime` was 224 ms for the
  retained evidence run.
- PID `18541` remained alive. `MainActivity` was resumed and not stopped, with a
  visible, focused window.
- App-scoped logcat records Vulkan Impeller, successful loading of
  `libirondash_engine_context_native.so` and `libsuper_native_extensions.so`,
  `App started`, and navigation to `home`. It contains no fatal exception,
  `MissingPluginException`, unhandled exception, or native crash signal.
- Evidence:
  `D:\files\Notea_Mirror\evidence\notea-m0-oppo-device-20260724.log`,
  `notea-m0-oppo-launch-20260724.log`,
  `notea-m0-oppo-activity-20260724.log`,
  `notea-m0-oppo-app-logcat-20260724.log`, and
  `notea-m0-oppo-release-pass-20260724.png`.

## M0 checklist

- [x] Windows Hypervisor Platform usable
- [x] Android SDK API 36 and `adb` usable
- [x] Flutter 3.44.1 and `flutter doctor -v` pass
- [x] Rust stable and aarch64 Android target (plus other build ABIs)
- [x] `NoteDev_API36_Tablet` created and booted
- [x] Butterfly v2.5.3 exact commit and pristine branch verified
- [x] Baseline tests saved
- [x] Official, debug, profile, and release APKs saved
- [x] Release APK starts on API 36 AVD
- [x] Toolchain lock and reproducible scripts committed
- [x] Physical device USB debugging authorized (`5370fdbb`)
- [x] Corrected release APK starts on the connected OPlus physical device

M0 is complete for the recorded source, toolchain, AVD, and connected physical
device. This does not by itself accept later feature milestones, stylus behavior,
performance targets, or long-duration stability.
