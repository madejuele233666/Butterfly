param(
    [ValidateSet("doctor", "pub-get", "test", "build-debug", "build-profile", "build-release", "clean-android", "devices")]
    [string]$Action,
    [string]$EvidenceDirectory = "D:\files\Notea_Mirror\evidence"
)

$ErrorActionPreference = "Stop"

$MirrorRoot = "D:\files\Notea_Mirror"
$Workspace = Join-Path $MirrorRoot "workspace"
$AppRoot = Join-Path $Workspace "app"
$FlutterRoot = Join-Path $MirrorRoot "toolchains\flutter"
$AndroidSdk = Join-Path $MirrorRoot "toolchains\AndroidSdk"
$AndroidStudio = Join-Path $MirrorRoot "toolchains\AndroidStudio"
$Flutter = Join-Path $FlutterRoot "bin\flutter.bat"
$CmdRunner = Join-Path $Workspace "scripts\windows-m0.cmd"

$GitCandidates = @(
    "D:\install_software\Git\cmd",
    "$env:ProgramFiles\Git\cmd"
)
$GitDirectory = $GitCandidates | Where-Object {
    Test-Path (Join-Path $_ "git.exe")
} | Select-Object -First 1

if (-not $GitDirectory) {
    throw "Git for Windows was not found in a supported installation path."
}
if (-not (Test-Path $Flutter)) {
    throw "Flutter was not found at $Flutter."
}
if (-not (Test-Path $AppRoot)) {
    throw "Windows mirror workspace was not found at $AppRoot."
}
if (-not (Test-Path $CmdRunner)) {
    throw "The Windows command runner was not found at $CmdRunner. Synchronize the mirror first."
}

New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null

$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:ANDROID_AVD_HOME = Join-Path $MirrorRoot "avd"
$env:JAVA_HOME = Join-Path $AndroidStudio "jbr"
$env:Path = @(
    "$env:SystemRoot\System32",
    $GitDirectory,
    (Join-Path $FlutterRoot "bin"),
    (Join-Path $AndroidSdk "platform-tools"),
    (Join-Path $AndroidSdk "emulator"),
    (Join-Path $AndroidSdk "cmdline-tools\latest\bin"),
    $env:Path
) -join ";"

Set-Location $AppRoot
Write-Host "Running Windows M0 action '$Action' from $AppRoot"
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = "$env:SystemRoot\System32\cmd.exe"
$startInfo.Arguments = '/d /s /c ""{0}" {1} "{2}""' -f $CmdRunner, $Action, $EvidenceDirectory
$startInfo.WorkingDirectory = $AppRoot
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
if (-not $process.Start()) {
    throw "Unable to start Flutter."
}
$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()
$process.WaitForExit()
$stdout = $stdoutTask.Result
$stderr = $stderrTask.Result
if ($stdout) { Write-Host $stdout.TrimEnd() }
if ($stderr) { Write-Host $stderr.TrimEnd() }
$exitCode = $process.ExitCode
Write-Host "Windows M0 action exit code: $exitCode"
exit $exitCode
