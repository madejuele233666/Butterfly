# 规划包变更记录

## 1.1.2 — 2026-07-25

- F0/F50 Legacy oracle 在 OPD2413 `devProfile` 上分别达到三轮有效运行；
- 用三个独立冷启动 F50 trace 取代合并 trace，使冻结的“三轮各自百分位
  中位数”可以直接计算；
- 增加 SQL-backed Perfetto owner 分析和确定性性能聚合，不再把字符串表
  出现次数当作 slice 证据；
- F0 空 renderer 集上的 `selection.raycast` 记录为不适用，不为制造 trace
  伪造工作；
- M1→M2 门已打开，M2 实现及 M3–M8 退出门保持未完成；
- 两次外部焦点中断导致的 ANR 作为后续渲染风险证据保留，不计入同条件
  基线。

## 1.1.1 — 2026-07-25

- 根据当前 OPD2413 真机证据，从下游责任切换反推 M1→M8 的必要门槛；
- M2 改为 Legacy oracle、owner-boundary replay、两档 fixture 三轮 Profile 和预冻结裁决规则；
- M3/M4 改为按已实现命令和明确子集进行 Shadow/Authority 切换；
- M5/M6 分别按几何能力和文档/session/UI owner 独立验收；
- M7/M8 只在活动墨迹或 stable renderer 被证明为首个瓶颈时触发；
- 需求基线和需求 SHA-256 不变。

## 1.1.0 — 2026-07-24

- 整合 Android Studio、AVD、真机 USB/Wi-Fi 联调；
- 增加 Debug/Profile/Release 变体纪律；
- 增加 OPPO Pencil 2 原生输入探针；
- 增加 Flutter/Perfetto/Simpleperf 联合性能流程；
- 明确 Root 只读诊断边界；
- 将主计划切成 M0–M6 与独立 Gate 的直接执行文档；
- 附 PowerShell 脚本、schema、模板和测试矩阵；
- SQLite 与需求基线不变。

## 1.0.1

- 保留 SQLite；更新 WAL/schema/备份/完整性意见。

## 1.0.0

- 初始深度调研与冻结计划。
