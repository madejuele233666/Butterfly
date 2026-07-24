# 05 / M3：Rust 影子后端

## 目标

同一命令同时送入 Legacy Dart 和 Rust。Legacy 继续作为唯一用户可见真相；Rust 只输出规范化状态和差异。此阶段不让 Rust 保存真实笔记。

## 开始门

- M2 的 Command、Delta、revision 与 history cursor 合同已经稳定；
- 同一 owner-boundary replay 能在 Legacy 上确定性复现并通过 M2 oracle；
- canonical state 明确哪些字段有业务语义，哪些只是缓存或瞬态显示状态；
- ID、浮点、元素顺序和旧字段缺失的规范化规则在看到 Rust diff 前冻结。

M3 只验证“同一有效命令是否得到同一业务状态”。数据库耐久性、发布体验、活动墨迹延迟和 tile cache 不属于本阶段责任。

## 步骤

1. 建立 `rust/` workspace，按主计划拆分 core/geometry/index/storage/backend/bridge。
2. 先实现内存 `note_core`，不接 SQLite。
3. 实现 Butterfly → canonical state 导入器。
4. 命令由 Dart 生成一次，序列化后分别发送给 Legacy 和 Rust。
5. 每次命令后比较：revision、元素 IDs、header、payload、history cursor，以及可与 M2 oracle 对应的 Delta 集合。
6. 差异写入有上限的调试文件，不阻塞 UI。
7. 用固定 trace 回放，而不是仅靠人工点击。
8. 为 float、ID、元素顺序和旧数据缺失字段建立规范化规则。

## 失败处理

差异必须归因到：

- 需求语义不同；
- Legacy 行为 bug；
- Rust 实现 bug；
- 规范化规则不足；
- 非确定性 ID/时间字段。

禁止用“忽略更多字段”把实质差异消掉。

## 退出门槛

- [ ] V1 最小命令集可在 Rust 执行；
- [ ] M2 固定 fixtures/replay 的逐命令规范化状态和 Delta 100% 一致；
- [ ] 版本化的随机/属性序列覆盖所有已实现命令，零未解释差异；
- [ ] 每个差异都归因到明确 owner，未通过扩大 ignore list 隐藏；
- [ ] Shadow 的队列、diff 文件和失败传播有界，不改变 Legacy 用户可见结果；
- [ ] 关闭 Shadow 后仍是原 M2 路径；开启 Shadow 的开销已量化，未越过预先冻结的调试可用阈值。
