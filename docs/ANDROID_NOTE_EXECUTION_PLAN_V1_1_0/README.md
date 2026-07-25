# Android 高性能手写笔记软件：分步执行包 v1.1.1

本包把主计划切成可以独立执行、独立验收和独立回退的阶段。它不是按字数拆分，而是按“一个阶段只改变一个主要不确定性”的原则组织。

## 不变基线

- 目标设备：OPPO Pad 4 Pro / Android 16 / 120 Hz / OPPO Pencil 2
- 主仓库：Butterfly `v2.5.3`
- 路线：保持行为不变地抽离后端 → Rust 影子执行 → Rust 权威后端
- 数据库：SQLite；journal/synchronous 由真机基准决定
- 需求基线 SHA-256：`1678bb842326cc7a1391b8c31e93b262e39f3e03abe55082b8d94d9f70790bcf`

## 执行顺序

1. `00_PROJECT_BASELINE`：阅读冻结需求、决策和执行规则。
2. `01_M0_TOOLCHAIN_AND_PRISTINE_BASELINE`：安装工具链并构建原版。
3. `02_M1_DEVICE_AND_STYLUS_PROBE`：连接真机并确认普通应用可观察的 Pencil 事件事实；精确快捷键/掌托语义按功能触发隔离采集。
4. `03_M1_PERFORMANCE_BASELINE`：冻结 Legacy 行为 oracle、owner-boundary replay 和 M2 定向性能基线。
5. `04_M2_BACKEND_BOUNDARY`：抽离 Legacy 后端接口，不改变行为。
6. `05_M3_RUST_SHADOW_BACKEND`：Rust 影子执行与规范化状态对比。
7. `06_M4_RUST_SQLITE_AUTHORITY`：Rust + SQLite 接管最小原型。
8. `07_M5_EDITING_GEOMETRY`：局部擦除、套索和移动。
9. `08_M6_PAGED_DOCUMENT_AND_UX`：分页、恢复和最小工具栏。
10. `09_DECISION_GATES`：Jetpack Ink、Tile Cache、Root 等独立决策门。
11. `10_DAILY_OPERATIONS`：日常调试、备份、恢复和发布使用。

## 执行规则

- 不满足当前所有权切换门，不切换对应 owner；不改变所有权的加法准备工作可以先行。
- 不在一个提交中同时改变后端真相、渲染器和输入链路。
- 模拟器只证明逻辑；真机 Profile/Release 才能证明性能。
- Root 只作只读诊断，不成为 V1 依赖。
- 每次实验必须填写 `RUN_RECORD_TEMPLATE.json`。
- 原始需求 JSON 只读，任何变化追加新的决策记录。
- 完整产品矩阵只在对应发布或技术决策门触发时成为阻塞项，不能代替当前 owner 的确定性 oracle。

完整计划与全部原始问答位于 `90_MASTER_AND_REFERENCE`。

## 当前执行状态（2026-07-25）

- M0：完成；工具链、AVD、原版基线、USB 真机和最小 Windows Build
  Tools 均已有证据。
- M1 输入探针：M2 所需输入事实完成；精确快捷键/掌托语义仍按未来功能
  owner 触发隔离测试。
- M1 行为与性能基线：完成；F0/F50 三轮行为通过，F50 三个独立
  Profile run 的帧/owner 百分位已冻结，人工 stroke/save owner 已观察。
- M1 → M2：门已打开，允许进入第一个可回滚 Handler cutover。
- M2：尚未实施。接下来只抽离 Legacy 后端边界并保持 Legacy 为唯一真相；
  每个迁移提交必须回放同一 oracle 并与 pre-M2 基线比较。
- M3–M6 及 Jetpack Ink/tile/发布门：顺序和责任边界不变，不因 M1
  完成而提前宣称通过。
