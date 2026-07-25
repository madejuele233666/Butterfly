# 性能基线检查表

- [x] 使用 devProfile
- [x] profileable/调试 trace 已启用
- [x] Device Mirroring 关闭
- [x] 录屏关闭
- [x] 温度/电量/刷新率已记录
- [x] 数据集 hash 已记录
- [x] 操作轨迹固定
- [x] Legacy 行为 oracle 覆盖 Create/Erase/PartialErase/Translate/Undo/Redo/取消/保存重开
- [x] replay 在 owner boundary 确定性驱动并记录版本
- [x] 空文档和代表性压力文档各至少三轮
- [x] 全部适用 owner trace 在真实 document canvas 上出现
- [x] 行为相等规则和性能回归阈值在 post-M2 数据前冻结
- [x] P50/P95/P99 使用 nearest-rank 并按三轮中位数聚合
- [ ] 编辑后重新书写的产品体验单独测试（后续渲染/发布门，不阻塞 M2）
- [x] trace 名称稳定
- [x] 三方对比、完整规模曲线、personalRelease 与光学录像未被误写成 M2 阻塞项
- [x] `prepare-m2-baseline` 在锁定依赖上以 `--no-pub` 通过
- [x] F0/F50 各自三轮 oracle 通过 `m1_validate_oracle.py`
- [x] sequence revision/history position 明确标为 Legacy 诊断坐标
- [x] 自动 owner trace 与人工 stroke/save owner trace 的证据职责分开

F0 无可见 renderer，`selection.raycast` 在其输入合同下不可达；F0 负责
空状态/帧基线，全部八个 owner 的回归基线由 F50 三个独立 run 负责。
