# 01 / M0：工具链与不可变 Butterfly 基线

## 目标

证明任何人都能从固定版本重新构建原版，并让 AVD 与 OPPO 真机运行同一提交。此阶段不修改产品行为。

## 前置条件

- 已完成 `00_PROJECT_BASELINE`；
- Windows BIOS 已开启虚拟化；
- 有可用 USB 数据线；
- 用户 fork URL 已准备。

## 步骤

### 1. 安装工具

安装 Android Studio stable。SDK Manager 选择 API 36、Build Tools、Platform Tools、Command-line Tools、Emulator、NDK、CMake。

安装 Flutter 3.44.1，并避免全局 `flutter upgrade` 改变本项目。

安装 Rust stable：

```powershell
rustup toolchain install stable
rustup default stable
rustup target add aarch64-linux-android
```

### 2. 运行预检

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\00_preflight.ps1
```

任何 FAIL 都先修复，不继续。

### 3. 创建 AVD

按照 `AVD_SETUP.md` 创建 `NoteDev_API36_Tablet`，运行一次并确认 `adb devices` 可见。

### 4. 克隆并锁定 v2.5.3

```powershell
.\scripts\01_clone_baseline.ps1 -RepoUrl "<YOUR_FORK_URL>" -Destination "D:\Projects\butterfly-note"
```

脚本只创建本地 baseline 和 work 分支，不自动 push。

### 5. 原样构建

```powershell
cd D:\Projects\butterfly-note\app
flutter pub get
flutter run -d <AVD_ID>
flutter run -d <OPPO_DEVICE_ID>
```

### 6. 锁定环境

```powershell
.\scripts\02_capture_toolchain.ps1 -Output "artifacts\toolchain-lock.env"
```

## 禁止

- 不升级依赖；
- 不修改 `DocumentBloc`；
- 不加入 Rust；
- 不修改数据库；
- 不合并 2.6 beta；
- 不对原版性能做未经记录的“顺手优化”。

## 退出门槛

- [ ] `v2.5.3` commit 被校验；
- [ ] AVD 能启动原版；
- [ ] OPPO 真机能启动原版；
- [ ] `flutter test` 当前基线结果已保存；
- [ ] 工具版本已记录；
- [ ] `baseline/v2.5.3-pristine` 永久无修改。

## 交付物

- `artifacts/toolchain-lock.env`；
- 原版 APK；
- AVD/真机启动截图或日志；
- 基线测试结果；
- baseline commit SHA。
