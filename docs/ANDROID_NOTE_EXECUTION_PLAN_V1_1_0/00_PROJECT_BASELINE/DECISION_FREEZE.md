# 冻结决策

| 项目 | 当前决策 | 改变方式 |
|---|---|---|
| 完整应用基线 | Butterfly v2.5.3 | 新建 ADR，不直接覆盖 |
| 目标设备 | OPPO Pad 4 Pro / Android 16 / OPPO Pencil 2 | 需求版本升级 |
| 主后端 | Rust | Gate C 裁决 |
| 数据库 | SQLite | 实现变更 ADR；V1 不再调研替换 |
| 文档模式 | 创建时分页/无限二选一 | 需求版本升级 |
| Root | 只读诊断，不是运行依赖 | Root Gate 记录 |
| Jetpack Ink | 条件 Spike | Gate A 记录 |
| Tile Cache | 条件重构 | Gate B 记录 |

禁止把“当前实现方便”当成需求变更理由。
