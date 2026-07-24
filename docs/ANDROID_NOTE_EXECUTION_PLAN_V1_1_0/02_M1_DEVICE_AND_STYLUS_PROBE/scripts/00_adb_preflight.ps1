$ErrorActionPreference = "Stop"
adb start-server | Out-Null
$devices = adb devices -l
$devices
$online = $devices | Select-String '\sdevice\s'
if (-not $online) { throw "No authorized Android device found" }
flutter devices
