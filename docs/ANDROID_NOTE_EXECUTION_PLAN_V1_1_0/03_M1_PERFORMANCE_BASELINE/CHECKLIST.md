# 性能基线检查表

- [ ] 使用 devProfile
- [ ] profileable 已启用
- [ ] Device Mirroring 关闭
- [ ] 录屏关闭
- [ ] 温度/电量/刷新率已记录
- [ ] 数据集 hash 已记录
- [ ] 操作轨迹固定
- [ ] Legacy 行为 oracle 覆盖 Create/Erase/PartialErase/Translate/Undo/Redo/取消/保存重开
- [ ] replay 在 owner boundary 确定性驱动并记录版本
- [ ] 空文档和代表性压力文档各至少三轮
- [ ] owner trace 在真实 document canvas 上出现
- [ ] 行为相等规则和性能回归阈值在 post-M2 数据前冻结
- [ ] P50/P95/P99 而非只看平均值
- [ ] 编辑后重新书写被单独测试
- [ ] trace 名称稳定
- [ ] 三方对比、完整规模曲线、personalRelease 与光学录像未被误写成 M2 阻塞项
