# Gate C：Rust 权威切换门

## 决策问题

Rust 是否可以成为一个明确命令子集的唯一文档 writer。切换单位是命令子集，不是笼统的“整个 V1”。

## 进入条件

- 将要接管的命令在 M2 replay 和版本化属性序列上达到零未解释 Shadow 差异；
- canonical state、schema、payload、revision、transaction 和恢复语义已冻结；
- 未迁移写功能可以明确关闭或保持只读；
- SQLite 配置、故障恢复、备份恢复和目标真机阈值已有可重复证据；
- feature flag 回退不会让 Legacy 与 Rust 同时写同一文档。

## 接受条件

- Rust actor 是接管子集的唯一 writer；
- commit 后才发布稳定 Delta，失败不推进 revision；
- 正常关闭、force-stop、事务/迁移中断均恢复到定义的事务边界；
- 同 fixture/replay 通过预冻结行为和性能规则；
- 回退演练成功且没有双写或隐式状态合并。

未满足时继续 Shadow 或缩小接管子集，不通过下游重试、默认文档、双写同步或放宽 parity 规则绕过。
