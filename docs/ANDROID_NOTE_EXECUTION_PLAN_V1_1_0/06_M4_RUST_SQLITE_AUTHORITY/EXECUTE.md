# 06 / M4：Rust + SQLite 权威最小原型

## 目标

Rust 成为无限画布最小原型的唯一文档真相，支持单支压力笔、整笔擦除、撤销、重启恢复。Flutter 继续负责活动笔画和稳定渲染。

## 切换范围

只接管：

- Infinite document；
- CreateStroke；
- EraseStrokes；
- Undo/Redo；
- viewport query；
- SQLite transaction；
- session restore。

局部擦除、套索和分页仍使用旧路径或暂时关闭，不能半接管。

## 权威切换门

Rust 只有在本节列出的最小命令子集满足以下条件后才能成为该子集的唯一 writer：

1. 同一 M2 replay 在 Shadow 模式逐命令零未解释差异；
2. schema、payload version、transaction boundary、revision 与恢复语义已经冻结；
3. 新建、正常关闭、force-stop、事务中断、迁移中断、备份与恢复在 owner boundary 有可重复测试；
4. SQLite 配置用同一命令 trace 在目标真机裁决，阈值在对照数据出现前冻结；
5. feature flag 回退路径经过演练，且 Legacy 与 Rust 不会同时写同一文档。

未迁移功能必须明确只读或关闭。用旧路径继续写、随后“同步”到 Rust 会制造两个真相源，不是可接受的兼容方案。

## 步骤

1. 实现 `DocumentSession` 单写者 actor。
2. 使用 `sql/schema_v1_1.sql` 创建每文档数据库。
3. 打开时加载 element headers/payload，重建内存 R-tree。
4. 活动点留在 Flutter；抬笔后一次提交完整 StrokeDraft。
5. 同一 SQLite transaction 写元素、history、revision、session cursor。
6. Command commit 后返回 Delta；Flutter 只增量更新 Renderer cache。
7. 实现 app-level library DB 或最小 session pointer，实现直接恢复。
8. 按 `09_DECISION_GATES/SQLITE_PROFILE_GATE.md` 用同一 trace 运行三种配置的 OPPO 真机对照。
9. 完成强制杀进程、重启和 integrity check。
10. Rust 权威切换必须由 feature flag 控制，可回到 Legacy 读取同一 fixture，但不得让两者同时写同一文件。

## SQLite 纪律

- 只由 Rust actor 持有 writer connection；
- 不在 pointer MOVE 路径访问 DB；
- 大 BLOB 表使用 INTEGER PRIMARY KEY rowid + stable UUID；
- 不预设 WAL + NORMAL 最优；
- 不用长 busy_timeout 掩盖内部竞争；
- 活跃 DB 备份用 Online Backup API 或 `VACUUM INTO`；
- schema version 与 payload version 分离。

## 退出门槛

- [ ] Rust 是最小功能唯一真相；
- [ ] SQLite revision 与内存 revision 始终一致；
- [ ] kill -9/force-stop 后恢复到完整事务边界；
- [ ] 代表性写入与打开指标通过预先冻结的阈值；完整规模曲线只在容量/渲染决策需要时扩展；
- [ ] 数据库维护不进入书写实时路径；
- [ ] feature flag 回退、备份恢复和单 writer 约束均有可重复证据；
- [ ] personalRelease 连续真实书写作为 M4 后的日用/发布验收，不替代上述权威切换证据。
