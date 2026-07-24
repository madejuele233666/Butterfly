# 05 / M3：Rust 影子后端

## 目标

同一命令同时送入 Legacy Dart 和 Rust。Legacy 继续作为唯一用户可见真相；Rust 只输出规范化状态和差异。此阶段不让 Rust 保存真实笔记。

## 步骤

1. 建立 `rust/` workspace，按主计划拆分 core/geometry/index/storage/backend/bridge。
2. 先实现内存 `note_core`，不接 SQLite。
3. 实现 Butterfly → canonical state 导入器。
4. 命令由 Dart 生成一次，序列化后分别发送给 Legacy 和 Rust。
5. 每次命令后比较：revision、元素 IDs、header、payload、history cursor。
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
- [ ] 固定 fixtures 的规范化状态 100% 一致；
- [ ] 10,000 命令随机序列无未解释差异；
- [ ] Shadow 模式不会明显破坏 Debug 交互；
- [ ] Profile 基准关闭 Shadow 后与 M1 可比。
