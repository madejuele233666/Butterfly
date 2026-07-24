param([string]$Output = "toolchain-lock.env")
$ErrorActionPreference = "Continue"
$lines = @()
$lines += "CAPTURED_AT=$(Get-Date -Format o)"
$lines += "WINDOWS=$([System.Environment]::OSVersion.VersionString)"
$lines += "GIT=$((git --version) -join ' ')"
$lines += "ADB=$((adb --version | Select-Object -First 1) -join ' ')"
$lines += "FLUTTER=$((flutter --version | Select-Object -First 1) -join ' ')"
$lines += "DART=$((dart --version 2>&1) -join ' ')"
$lines += "RUSTC=$((rustc --version) -join ' ')"
$lines += "CARGO=$((cargo --version) -join ' ')"
$lines += "JAVA=$((java -version 2>&1 | Select-Object -First 1) -join ' ')"
$dir = Split-Path -Parent $Output
if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$lines | Set-Content -Encoding UTF8 $Output
Get-Content $Output
