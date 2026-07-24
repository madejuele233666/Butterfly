param([string]$OutputDir = "device-info")
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
adb shell getprop | Set-Content -Encoding UTF8 "$OutputDir\getprop.txt"
adb shell wm size | Set-Content -Encoding UTF8 "$OutputDir\wm-size.txt"
adb shell wm density | Set-Content -Encoding UTF8 "$OutputDir\wm-density.txt"
adb shell dumpsys display | Set-Content -Encoding UTF8 "$OutputDir\dumpsys-display.txt"
adb shell dumpsys input | Set-Content -Encoding UTF8 "$OutputDir\dumpsys-input.txt"
adb shell settings get system peak_refresh_rate | Set-Content -Encoding UTF8 "$OutputDir\peak-refresh-rate.txt"
adb shell settings get system min_refresh_rate | Set-Content -Encoding UTF8 "$OutputDir\min-refresh-rate.txt"
adb shell getprop ro.build.fingerprint | Set-Content -Encoding UTF8 "$OutputDir\build-fingerprint.txt"
Write-Host "Captured device information to $OutputDir"
