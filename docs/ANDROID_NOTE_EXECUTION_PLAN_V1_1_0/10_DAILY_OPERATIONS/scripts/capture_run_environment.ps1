param([string]$Output = "run-environment.txt")
$lines = @()
$lines += "captured_at=$(Get-Date -Format o)"
$lines += "device=$(adb shell getprop ro.product.model)"
$lines += "fingerprint=$(adb shell getprop ro.build.fingerprint)"
$lines += "battery=$(adb shell dumpsys battery | Out-String)"
$lines += "peak_refresh_rate=$(adb shell settings get system peak_refresh_rate)"
$lines += "min_refresh_rate=$(adb shell settings get system min_refresh_rate)"
$lines += "thermal=$(adb shell dumpsys thermalservice | Out-String)"
$lines | Set-Content -Encoding UTF8 $Output
Write-Host "Captured to $Output"
