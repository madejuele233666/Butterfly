param([string]$Output = "logcat.txt", [string]$Package = "")
$ErrorActionPreference = "Stop"
adb logcat -c
Write-Host "Press Ctrl+C to stop capture."
if ($Package) {
    $pid = (adb shell pidof $Package).Trim()
    if (-not $pid) { throw "Package process not running: $Package" }
    adb logcat --pid=$pid -v threadtime | Tee-Object -FilePath $Output
} else {
    adb logcat -v threadtime | Tee-Object -FilePath $Output
}
