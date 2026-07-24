# 02 / M1-A：真机连接与 OPPO Pencil 2 输入探针

## 目标

建立设备事实，不根据宣传页或其他 OPPO 笔推断 Pencil 2。回答压力、历史样本、倾角、悬停、侧键和掌托取消事件如何实际暴露。

## 前置条件

- M0 通过；
- 原版能在 OPPO 真机运行；
- 使用 `devDebug`，不需要 Root。

## 步骤

### 1. USB 连接

```powershell
.\scripts\00_adb_preflight.ps1
.\scripts\01_capture_device_info.ps1 -OutputDir artifacts\device-info
```

### 2. 无线调试

在 Android Studio 选择 `Pair Devices Using Wi-Fi`。无线连接只用于日常联调；能力探针和正式基准优先 USB。

### 3. 加入原生探针

参考 `templates/StylusProbePlugin.kt.template`。探针必须：

- 捕获当前和全部 historical samples；
- 使用内存 ring buffer；
- 测试结束后一次性导出；
- 不在每次 MOVE 上写文件或 Logcat；
- 正确处理 ACTION_CANCEL；
- 同时观察 MotionEvent、GenericMotionEvent 和 KeyEvent。

### 4. 运行动作矩阵

逐项执行 `STYLUS_TEST_MATRIX.md`，每项单独保存 trace。

### 5. 填能力报告

复制 `templates/CAPABILITY_REPORT.md` 到 `artifacts/` 并填写。不要把“未观察到”写成“不支持”；需要注明观察路径和构建版本。

### 6. Root 决策

若标准 API 已能解释侧键，不进入 Root。只有完全看不到且该功能仍关键时，转到 `09_DECISION_GATES/ROOT_DIAGNOSTIC_GATE.md`。

## 退出门槛

- [ ] 能证明是否存在 historical samples；
- [ ] 压力实际范围已记录；
- [ ] tilt/orientation/hover 是否存在已记录；
- [ ] 侧键是 down/up、双击、KeyEvent 还是不可见已记录；
- [ ] 手掌干扰的 CANCEL 行为已记录；
- [ ] 事件探针自身没有造成明显事件处理阻塞。

## 交付物

- `oppo-pencil2-capabilities.json`；
- 12 组 JSONL trace；
- 设备信息快照；
- 是否进入 Root 分支的 ADR。
