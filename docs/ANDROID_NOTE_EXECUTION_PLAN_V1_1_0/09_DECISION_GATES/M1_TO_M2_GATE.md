# M1 → M2 所有权切换门

## 决策问题

M2 的目的不是证明产品已经达到最终性能，而是在不改变 Legacy 行为的前提下，把写操作责任链从 `Handler → DocumentBloc` 改为 `Handler → Command → DocumentBackend → Delta`。因此门槛只覆盖这次所有权变化能够制造的风险。

## 可先行工作

以下加法变更不改变调用方所有权，可在输入探针事实建立后开始：

- Command DTO 与 DocumentDelta 合同；
- 尚未接管 Handler 的 Legacy adapter；
- oracle/replay harness 与 trace 观测点。

## 第一个 Handler 切换前必须满足

1. Legacy oracle 覆盖 CreateStroke、EraseStrokes、PartialErase、TranslateSelection、Undo、Redo、取消不提交和保存重开；
2. 每一步记录规范化文档状态、history cursor、revision 和 created/updated/removed 集合；
3. replay 在 owner boundary 确定性驱动，不依赖操作者手速；
4. 空文档和一个代表性压力文档分别在当前 instrumented `devProfile` 上至少运行三轮；
5. 行为相等规则和性能回归阈值在 post-M2 数据出现前冻结。

## 不阻塞 M2

- 十二项 Pencil 动作的逐项隔离 trace、精确快捷键与掌托语义；
- 纯 60 Hz 双指场景、Wi-Fi ADB、零售名称推断；
- Notein/原版/当前三方完整对照与全部规模曲线；
- personalRelease 长时间体验；
- 240/480 fps 光学延迟；
- M7 Jetpack Ink 与 M8 tile cache 的技术选型。

若 M2 实际改变上述任一责任边界，对应证据才升级为本次切换门槛。

## 裁决

- 五项必需证据齐全：允许逐 Handler 切换，每次独立回滚并运行同一 replay；
- 缺少任一项：DTO/adapter 等加法工作可继续，但不得切换第一个 Handler；
- post-M2 出现差异：定位第一个错误状态及其 owner，不通过放宽 normalization、改阈值或下游补偿掩盖。
