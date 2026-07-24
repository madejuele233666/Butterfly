# M2 检查表

- [ ] DocumentBackend 接口不泄露 Bloc/Renderer
- [ ] Command DTO 可序列化
- [ ] Delta 含 revision
- [ ] Handler 只发送 Command
- [ ] 选择状态逐步 ID 化
- [ ] Legacy 是唯一真相
- [ ] 第一个 Handler 切换前 Legacy oracle 与 owner-boundary replay 已冻结
- [ ] 空文档和代表性压力文档 pre-M2 基线各至少三轮
- [ ] 行为相等规则和性能回归阈值在 post-M2 数据前冻结
- [ ] 每个迁移提交可单独回滚
- [ ] parity tests 逐命令比较状态、history、revision 和 Delta
- [ ] 同 fixture/同 replay 的定向性能回归通过冻结规则
