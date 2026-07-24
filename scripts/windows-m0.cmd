@echo off
setlocal

set "MIRROR_ROOT=D:\files\Notea_Mirror"
set "WORKSPACE=%MIRROR_ROOT%\workspace"
set "APP_ROOT=%WORKSPACE%\app"
set "FLUTTER=%MIRROR_ROOT%\toolchains\flutter\bin\flutter.bat"
set "ANDROID_HOME=%MIRROR_ROOT%\toolchains\AndroidSdk"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "ANDROID_AVD_HOME=%MIRROR_ROOT%\avd"
set "JAVA_HOME=%MIRROR_ROOT%\toolchains\AndroidStudio\jbr"
set "PUB_CACHE=C:\Users\27866\AppData\Local\Pub\Cache"
set "CARGO_NET_GIT_FETCH_WITH_CLI=true"
set "GIT_CONFIG_COUNT=2"
set "GIT_CONFIG_KEY_0=url.ssh://git@ssh.github.com:443/.insteadOf"
set "GIT_CONFIG_VALUE_0=https://github.com/"
set "GIT_CONFIG_KEY_1=core.sshCommand"
set "GIT_CONFIG_VALUE_1=D:/files/Notea_Mirror/toolchains/wsl-ssh.cmd"
set "PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;D:\install_software\Git\cmd;%MIRROR_ROOT%\toolchains\flutter\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\emulator;%ANDROID_HOME%\cmdline-tools\latest\bin;C:\Users\27866\.cargo\bin"
set "PATHEXT=.COM;.EXE;.BAT;.CMD"

if not exist "%FLUTTER%" (
  echo Flutter was not found at %FLUTTER%. 1>&2
  exit /b 2
)
if not exist "%APP_ROOT%" (
  echo Windows mirror workspace was not found at %APP_ROOT%. 1>&2
  exit /b 2
)

cd /d "%APP_ROOT%"
if errorlevel 1 exit /b %ERRORLEVEL%

if /i "%~1"=="doctor" goto doctor
if /i "%~1"=="test" goto test
if /i "%~1"=="build-debug" goto build_debug
if /i "%~1"=="build-profile" goto build_profile
if /i "%~1"=="build-release" goto build_release
if /i "%~1"=="clean-android" goto clean_android
if /i "%~1"=="devices" goto devices

echo Usage: %~nx0 doctor^|test^|build-debug^|build-profile^|build-release^|clean-android^|devices 1>&2
exit /b 2

:doctor
call "%FLUTTER%" doctor -v
exit /b %ERRORLEVEL%

:test
set "EVIDENCE=%~2"
if not defined EVIDENCE set "EVIDENCE=%MIRROR_ROOT%\evidence"
if not exist "%EVIDENCE%" mkdir "%EVIDENCE%"
for /f %%i in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%i"
call "%FLUTTER%" test --no-pub --file-reporter "expanded:%EVIDENCE%\flutter-test-%STAMP%.log"
exit /b %ERRORLEVEL%

:build_debug
call :prepare_evidence "%~2"
set "BUILD_LOG=%EVIDENCE%\flutter-build-debug-%STAMP%.log"
call "%FLUTTER%" build apk --debug --flavor production --no-pub > "%BUILD_LOG%" 2>&1
set "BUILD_EXIT=%ERRORLEVEL%"
type "%BUILD_LOG%"
exit /b %BUILD_EXIT%

:build_release
call :prepare_evidence "%~2"
set "BUILD_LOG=%EVIDENCE%\flutter-build-release-%STAMP%.log"
call "%FLUTTER%" build apk --release --flavor production --no-pub > "%BUILD_LOG%" 2>&1
set "BUILD_EXIT=%ERRORLEVEL%"
type "%BUILD_LOG%"
exit /b %BUILD_EXIT%

:build_profile
call :prepare_evidence "%~2"
set "BUILD_LOG=%EVIDENCE%\flutter-build-profile-%STAMP%.log"
call "%FLUTTER%" build apk --profile --flavor production --no-pub > "%BUILD_LOG%" 2>&1
set "BUILD_EXIT=%ERRORLEVEL%"
type "%BUILD_LOG%"
exit /b %BUILD_EXIT%

:clean_android
cd /d "%APP_ROOT%\android"
call gradlew.bat --stop
if errorlevel 1 exit /b %ERRORLEVEL%
call gradlew.bat clean
exit /b %ERRORLEVEL%

:devices
call "%FLUTTER%" --verbose devices
exit /b %ERRORLEVEL%

:prepare_evidence
set "EVIDENCE=%~1"
if not defined EVIDENCE set "EVIDENCE=%MIRROR_ROOT%\evidence"
if not exist "%EVIDENCE%" mkdir "%EVIDENCE%"
for /f %%i in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%i"
exit /b 0
