$ErrorActionPreference = "Stop"

function Check-Command($Name, $Args = @("--version")) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Host "[FAIL] $Name not found" -ForegroundColor Red
        return $false
    }
    Write-Host "[OK] $Name -> $($cmd.Source)" -ForegroundColor Green
    try { & $Name @Args | Select-Object -First 5 } catch { Write-Warning $_ }
    return $true
}

$ok = $true
$ok = (Check-Command "git") -and $ok
$ok = (Check-Command "adb") -and $ok
$ok = (Check-Command "flutter") -and $ok
$ok = (Check-Command "dart") -and $ok
$ok = (Check-Command "rustc") -and $ok
$ok = (Check-Command "cargo") -and $ok
$ok = (Check-Command "java") -and $ok

Write-Host "`nFlutter doctor:" -ForegroundColor Cyan
flutter doctor -v

if ($env:ANDROID_HOME) {
    $emu = Join-Path $env:ANDROID_HOME "emulator\emulator.exe"
    if (Test-Path $emu) {
        & $emu -accel-check
    } else {
        Write-Warning "Emulator binary not found under ANDROID_HOME"
    }
} else {
    Write-Warning "ANDROID_HOME is not set"
}

if (-not $ok) { exit 1 }
