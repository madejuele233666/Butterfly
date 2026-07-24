param(
    [ValidateSet(
        "pub-get", "analyze", "test", "fixtures",
        "build-dev-debug", "build-dev-profile", "build-personal-release",
        "prepare-all", "start-probe", "pull-probe", "perfetto"
    )]
    [string]$Action = "prepare-all",
    [string]$Device,
    [string]$EvidenceDirectory = "D:\files\Notea_Mirror\evidence\m1"
)

$ErrorActionPreference = "Stop"

$MirrorRoot = "D:\files\Notea_Mirror"
$Workspace = Join-Path $MirrorRoot "workspace"
$AppRoot = Join-Path $Workspace "app"
$FlutterRoot = Join-Path $MirrorRoot "toolchains\flutter"
$AndroidSdk = Join-Path $MirrorRoot "toolchains\AndroidSdk"
$AndroidStudio = Join-Path $MirrorRoot "toolchains\AndroidStudio"
$Flutter = Join-Path $FlutterRoot "bin\flutter.bat"
$Dart = Join-Path $FlutterRoot "bin\dart.bat"
$Adb = Join-Path $AndroidSdk "platform-tools\adb.exe"

$GitDirectory = @(
    "D:\install_software\Git\cmd",
    "$env:ProgramFiles\Git\cmd"
) | Where-Object { Test-Path (Join-Path $_ "git.exe") } | Select-Object -First 1

foreach ($required in @($AppRoot, $Flutter, $Dart, $Adb, $GitDirectory)) {
    if (-not $required -or -not (Test-Path $required)) {
        throw "Required M1 tool or directory is missing: $required"
    }
}

$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:ANDROID_AVD_HOME = Join-Path $MirrorRoot "avd"
$env:JAVA_HOME = Join-Path $AndroidStudio "jbr"
$env:Path = @(
    "$env:SystemRoot\System32",
    $GitDirectory,
    (Join-Path $FlutterRoot "bin"),
    (Join-Path $AndroidSdk "platform-tools"),
    $env:Path
) -join ";"

New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $EvidenceDirectory "apk") | Out-Null
Set-Location $AppRoot

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments, [string]$LogName)
    $log = Join-Path $EvidenceDirectory $LogName
    & $Program @Arguments 2>&1 | Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed with exit code $LASTEXITCODE. See $log"
    }
}

function Build-Apk {
    param([string]$Flavor, [string]$Mode, [bool]$ProbeEnabled)
    $define = "M1_PROBE_ENABLED=$($ProbeEnabled.ToString().ToLowerInvariant())"
    Invoke-Checked $Flutter @(
        "build", "apk", "--$Mode", "--flavor", $Flavor,
        "--dart-define=$define", "--no-pub"
    ) "flutter-build-$Flavor-$Mode.log"
    $source = Join-Path $AppRoot "build\app\outputs\flutter-apk\app-$Flavor-$Mode.apk"
    if (-not (Test-Path $source)) { throw "Expected APK was not produced: $source" }
    Copy-Item -Force $source (Join-Path $EvidenceDirectory "apk\notea-m1-$Flavor-$Mode.apk")
}

function Require-Device {
    if (-not $Device) { throw "-Device is required for action '$Action'." }
}

switch ($Action) {
    "pub-get" { Invoke-Checked $Flutter @("pub", "get") "flutter-pub-get.log" }
    "analyze" { Invoke-Checked $Flutter @("analyze", "--no-pub") "flutter-analyze.log" }
    "test" { Invoke-Checked $Flutter @("test", "--no-pub") "flutter-test.log" }
    "fixtures" {
        Invoke-Checked $Dart @(
            "run", "tool\m1_fixture_generator.dart",
            (Join-Path $EvidenceDirectory "fixtures")
        ) "fixture-generator.log"
    }
    "build-dev-debug" { Build-Apk "dev" "debug" $true }
    "build-dev-profile" { Build-Apk "dev" "profile" $true }
    "build-personal-release" { Build-Apk "personal" "release" $false }
    "prepare-all" {
        Invoke-Checked $Flutter @("pub", "get") "flutter-pub-get.log"
        Invoke-Checked $Flutter @("analyze", "--no-pub") "flutter-analyze.log"
        Invoke-Checked $Flutter @("test", "--no-pub") "flutter-test.log"
        Invoke-Checked $Dart @(
            "run", "tool\m1_fixture_generator.dart",
            (Join-Path $EvidenceDirectory "fixtures")
        ) "fixture-generator.log"
        Build-Apk "dev" "debug" $true
        Build-Apk "dev" "profile" $true
        Build-Apk "personal" "release" $false
    }
    "start-probe" {
        Require-Device
        & $Adb -s $Device shell am force-stop dev.linwood.butterfly.dev.debug
        & $Adb -s $Device shell am start -S -n dev.linwood.butterfly.dev.debug/dev.linwood.butterfly.MainActivity --ez m1Probe true
        if ($LASTEXITCODE -ne 0) { throw "Unable to launch M1 probe." }
    }
    "pull-probe" {
        Require-Device
        $remote = (& $Adb -s $Device shell run-as dev.linwood.butterfly.dev.debug sh -c 'ls -1t files/app_flutter/m1-probe/*.jsonl | head -n 1').Trim()
        if (-not $remote) { throw "No exported M1 JSONL file was found." }
        $target = Join-Path $EvidenceDirectory (Split-Path $remote -Leaf)
        $bytes = & $Adb -s $Device exec-out run-as dev.linwood.butterfly.dev.debug cat $remote
        [System.IO.File]::WriteAllLines($target, $bytes)
        Write-Host "Pulled $remote to $target"
    }
    "perfetto" {
        Require-Device
        $config = Join-Path $Workspace "artifacts\m1\perfetto.cfg"
        $remote = "/data/misc/perfetto-traces/notea-m1.perfetto-trace"
        Get-Content -Raw $config | & $Adb -s $Device shell perfetto --txt -c - -o $remote
        if ($LASTEXITCODE -ne 0) { throw "Perfetto capture failed." }
        & $Adb -s $Device pull $remote (Join-Path $EvidenceDirectory "notea-m1.perfetto-trace")
        if ($LASTEXITCODE -ne 0) { throw "Perfetto pull failed." }
    }
}
