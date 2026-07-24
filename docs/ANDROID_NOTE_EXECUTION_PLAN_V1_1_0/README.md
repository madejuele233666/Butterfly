# Android 高性能手写笔记软件：分步执行包 v1.1.0

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
3. `02_M1_DEVICE_AND_STYLUS_PROBE`：连接真机并确认 OPPO Pencil 2 事件事实。
4. `03_M1_PERFORMANCE_BASELINE`：建立可复现性能基线。
5. `04_M2_BACKEND_BOUNDARY`：抽离 Legacy 后端接口，不改变行为。
6. `05_M3_RUST_SHADOW_BACKEND`：Rust 影子执行与规范化状态对比。
7. `06_M4_RUST_SQLITE_AUTHORITY`：Rust + SQLite 接管最小原型。
8. `07_M5_EDITING_GEOMETRY`：局部擦除、套索和移动。
9. `08_M6_PAGED_DOCUMENT_AND_UX`：分页、恢复和最小工具栏。
10. `09_DECISION_GATES`：Jetpack Ink、Tile Cache、Root 等独立决策门。
11. `10_DAILY_OPERATIONS`：日常调试、备份、恢复和发布使用。

## 执行规则

- 不满足当前阶段退出门槛，不进入下一阶段。
- 不在一个提交中同时改变后端真相、渲染器和输入链路。
- 模拟器只证明逻辑；真机 Profile/Release 才能证明性能。
- Root 只作只读诊断，不成为 V1 依赖。
- 每次实验必须填写 `RUN_RECORD_TEMPLATE.json`。
- 原始需求 JSON 只读，任何变化追加新的决策记录。

完整计划与全部原始问答位于 `90_MASTER_AND_REFERENCE`。
