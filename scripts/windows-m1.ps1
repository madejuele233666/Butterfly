param(
    [ValidateSet(
        "pub-get", "analyze", "test", "fixtures",
        "build-dev-debug", "build-dev-profile", "build-personal-release",
        "prepare-all", "prepare-m2-baseline", "start-probe", "pull-probe",
        "start-baseline", "pull-baseline", "perfetto"
    )]
    [string]$Action = "prepare-all",
    [string]$Device,
    [ValidateSet("F0", "F1", "F10", "F50")]
    [string]$Fixture = "F0",
    [ValidateRange(1, 10)]
    [int]$Runs = 3,
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
$WindowsRoot = if ($env:SystemRoot) { $env:SystemRoot } else { "C:\Windows" }

$GitDirectory = @(
    "D:\install_software\Git\cmd",
    "$env:ProgramFiles\Git\cmd"
) | Where-Object { Test-Path (Join-Path $_ "git.exe") } | Select-Object -First 1
$Git = if ($GitDirectory) { Join-Path $GitDirectory "git.exe" } else { $null }

foreach ($required in @($AppRoot, $Flutter, $Dart, $Adb, $Git)) {
    if (-not $required -or -not (Test-Path $required)) {
        throw "Required M1 tool or directory is missing: $required"
    }
}

$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:ANDROID_AVD_HOME = Join-Path $MirrorRoot "avd"
$env:JAVA_HOME = Join-Path $AndroidStudio "jbr"
$env:PATHEXT = ".COM;.EXE;.BAT;.CMD"
$env:PUB_CACHE = "C:\Users\27866\AppData\Local\Pub\Cache"
$env:CARGO_NET_GIT_FETCH_WITH_CLI = "true"
$env:Path = @(
    "$WindowsRoot\System32",
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
    $quotedArguments = $Arguments | ForEach-Object {
        if ($_ -match '[\s"]') { '"{0}"' -f ($_ -replace '"', '\"') } else { $_ }
    }
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "$WindowsRoot\System32\cmd.exe"
    $startInfo.Arguments = '/d /s /c ""{0}" {1}"' -f $Program, ($quotedArguments -join ' ')
    $startInfo.WorkingDirectory = $AppRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.EnvironmentVariables["PATH"] = $env:Path
    $startInfo.EnvironmentVariables["ANDROID_HOME"] = $env:ANDROID_HOME
    $startInfo.EnvironmentVariables["ANDROID_SDK_ROOT"] = $env:ANDROID_SDK_ROOT
    $startInfo.EnvironmentVariables["ANDROID_AVD_HOME"] = $env:ANDROID_AVD_HOME
    $startInfo.EnvironmentVariables["JAVA_HOME"] = $env:JAVA_HOME
    $startInfo.EnvironmentVariables["PATHEXT"] = $env:PATHEXT
    $startInfo.EnvironmentVariables["PUB_CACHE"] = $env:PUB_CACHE
    $startInfo.EnvironmentVariables["CARGO_NET_GIT_FETCH_WITH_CLI"] = $env:CARGO_NET_GIT_FETCH_WITH_CLI
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "Unable to start $Program" }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    [System.IO.File]::WriteAllText($log, $stdout + $stderr)
    if ($stdout) { Write-Host $stdout.TrimEnd() }
    if ($stderr) { Write-Host $stderr.TrimEnd() }
    if ($process.ExitCode -ne 0) {
        throw "$Program failed with exit code $($process.ExitCode). See $log"
    }
}

function Build-Apk {
    param([string]$Flavor, [string]$Mode, [bool]$ProbeEnabled)
    $sourceCommit = (& $Git -C $Workspace rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $sourceCommit) {
        throw "Unable to resolve the source commit for the APK."
    }
    $sourceChanges = @(& $Git -C $Workspace status --porcelain)
    if ($LASTEXITCODE -ne 0) { throw "Unable to inspect the source worktree." }
    if ($sourceChanges.Count -ne 0) {
        throw "Refusing a provenance build from a dirty Windows worktree."
    }
    $buildDirectory = Join-Path $AppRoot "build"
    if (Test-Path $buildDirectory) {
        Remove-Item -Recurse -Force $buildDirectory
    }
    $define = "M1_PROBE_ENABLED=$($ProbeEnabled.ToString().ToLowerInvariant())"
    Invoke-Checked $Flutter @(
        "build", "apk", "--$Mode", "--flavor", $Flavor,
        "--dart-define=$define", "--no-pub"
    ) "flutter-build-$Flavor-$Mode.log"
    $source = Join-Path $AppRoot "build\app\outputs\flutter-apk\app-$Flavor-$Mode.apk"
    if (-not (Test-Path $source)) { throw "Expected APK was not produced: $source" }
    $target = Join-Path $EvidenceDirectory "apk\notea-m1-$Flavor-$Mode.apk"
    Copy-Item -Force $source $target
    $provenance = [ordered]@{
        schema = "notea.m1.apk-provenance/v1"
        sourceCommit = $sourceCommit
        sourceWorktreeClean = $true
        builtAtUtc = [DateTime]::UtcNow.ToString("o")
        flavor = $Flavor
        mode = $Mode
        probeEnabled = $ProbeEnabled
        apk = (Split-Path $target -Leaf)
        apkBytes = (Get-Item $target).Length
        apkSha256 = (Get-FileHash -Algorithm SHA256 $target).Hash.ToLowerInvariant()
    }
    $provenance | ConvertTo-Json | Set-Content -Encoding utf8 `
        (Join-Path $EvidenceDirectory "apk\notea-m1-$Flavor-$Mode.provenance.json")
}

function Require-Device {
    if (-not $Device) { throw "-Device is required for action '$Action'." }
}

function Copy-RunAsFile {
    param(
        [string]$Package,
        [string]$Remote,
        [string]$Target
    )
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Adb
    $startInfo.Arguments = "-s $Device exec-out run-as $Package cat $Remote"
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stream = [System.IO.File]::Create($Target)
    try {
        $process.StandardOutput.BaseStream.CopyTo($stream)
        $process.WaitForExit()
        $pullExitCode = $process.ExitCode
    } finally {
        $stream.Dispose()
        $process.Dispose()
    }
    if ($pullExitCode -ne 0) { throw "Unable to pull $Remote" }
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
    "prepare-m2-baseline" {
        Invoke-Checked $Flutter @("analyze", "--no-pub") "flutter-analyze.log"
        Invoke-Checked $Flutter @(
            "test", "--no-pub",
            "test\debug\performance\m1_legacy_oracle_test.dart"
        ) "m1-legacy-oracle-test.log"
        Invoke-Checked $Dart @(
            "run", "tool\m1_fixture_generator.dart",
            (Join-Path $EvidenceDirectory "fixtures")
        ) "fixture-generator.log"
        Build-Apk "dev" "profile" $true
    }
    "start-probe" {
        Require-Device
        & $Adb -s $Device shell am force-stop dev.linwood.butterfly.dev.debug
        & $Adb -s $Device shell am start -S -n dev.linwood.butterfly.dev.debug/dev.linwood.butterfly.MainActivity --ez m1Probe true
        if ($LASTEXITCODE -ne 0) { throw "Unable to launch M1 probe." }
    }
    "pull-probe" {
        Require-Device
        $probeDirectory = "app_flutter/m1-probe"
        $exports = @(& $Adb -s $Device shell run-as dev.linwood.butterfly.dev.debug ls -1t $probeDirectory)
        if ($LASTEXITCODE -ne 0) { throw "Unable to list exported M1 JSONL files." }
        $fileName = $exports |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '^m1-.*\.jsonl$' } |
            Select-Object -First 1
        if (-not $fileName) { throw "No exported M1 JSONL file was found." }
        $remote = "$probeDirectory/$fileName"
        $target = Join-Path $EvidenceDirectory (Split-Path $remote -Leaf)
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $Adb
        $startInfo.Arguments = "-s $Device exec-out run-as dev.linwood.butterfly.dev.debug cat $remote"
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.CreateNoWindow = $true
        $process = [System.Diagnostics.Process]::Start($startInfo)
        $stream = [System.IO.File]::Create($target)
        try {
            $process.StandardOutput.BaseStream.CopyTo($stream)
            $process.WaitForExit()
            $pullExitCode = $process.ExitCode
        } finally {
            $stream.Dispose()
            $process.Dispose()
        }
        if ($pullExitCode -ne 0) { throw "Unable to pull M1 JSONL." }
        Write-Host "Pulled $remote to $target"
    }
    "start-baseline" {
        Require-Device
        $apk = Join-Path $EvidenceDirectory "apk\notea-m1-dev-profile.apk"
        if (-not (Test-Path $apk)) {
            throw "Profile APK is missing. Run -Action prepare-m2-baseline first."
        }
        & $Adb -s $Device install -r $apk
        if ($LASTEXITCODE -ne 0) { throw "Unable to install M1 profile APK." }
        & $Adb -s $Device shell am force-stop dev.linwood.butterfly.dev.profile
        & $Adb -s $Device shell am start -S -W `
            -n dev.linwood.butterfly.dev.profile/dev.linwood.butterfly.MainActivity `
            --ez trace-systrace true `
            --es m1BaselineFixture $Fixture --ei m1BaselineRuns $Runs
        if ($LASTEXITCODE -ne 0) { throw "Unable to launch M1 baseline." }
    }
    "pull-baseline" {
        Require-Device
        $package = "dev.linwood.butterfly.dev.profile"
        $targetDirectory = Join-Path $EvidenceDirectory "baseline"
        New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null

        $baselineDirectory = "files/m1-baseline"
        $baselineFiles = @(& $Adb -s $Device shell run-as $package ls -1t $baselineDirectory)
        if ($LASTEXITCODE -ne 0) { throw "Unable to list M1 baseline exports." }
        $baselineFile = $baselineFiles |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '^m1-baseline-.*\.json$' } |
            Select-Object -First 1
        if (-not $baselineFile) { throw "No M1 baseline JSON was found." }
        Copy-RunAsFile $package "$baselineDirectory/$baselineFile" `
            (Join-Path $targetDirectory $baselineFile)

        $probeDirectory = "app_flutter/m1-probe"
        $probeFiles = @(& $Adb -s $Device shell run-as $package ls -1t $probeDirectory)
        if ($LASTEXITCODE -ne 0) { throw "Unable to list M1 probe exports." }
        $selectedProbeFiles = $probeFiles |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '^m1-.*\.jsonl$' } |
            Select-Object -First $Runs
        if ($selectedProbeFiles.Count -ne $Runs) {
            throw "Expected $Runs probe JSONL files, found $($selectedProbeFiles.Count)."
        }
        foreach ($probeFile in $selectedProbeFiles) {
            Copy-RunAsFile $package "$probeDirectory/$probeFile" `
                (Join-Path $targetDirectory $probeFile)
        }
        Write-Host "Pulled baseline JSON and $Runs probe runs to $targetDirectory"
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
