# 决策日志

复制以下模板追加，不修改旧记录。

## ADR-0000：标题

- 日期：
- 状态：proposed / accepted / rejected / superseded
- 触发证据：
- 备选方案：
- 决策：
- 代价：
- 回滚条件：
- 影响的需求：无 / 列出需求 ID

## ADR-0001：按责任边界收敛 M1 到后续阶段的门槛

- 日期：2026-07-25
- 状态：accepted
- 触发证据：OPD2413 综合输入 trace 已证明普通应用可见的样本/轴/按键/CANCEL；60 Hz 请求在双指序列中由系统切到 120 Hz；现有 Profile run 位于探针页，未触发 document canvas 的 stroke/bake/raycast/save/history owners。
- 备选方案：在 M2 前强制完成十二项独立 trace、纯 60 Hz、Notein 三方对照、完整规模曲线、personalRelease 与光学录像；或不设 oracle 直接切 Handler。
- 决策：每次阶段门只覆盖该次责任所有权变化。M2 第一个 Handler 切换前必须冻结 Legacy oracle、确定性 owner-boundary replay、两档 fixture 各三轮 Profile 基线及预先定义的裁决规则；M3-M8 沿用同一原则。无关产品矩阵按对应发布或技术决策门触发。
- 代价：需要先实现 replay/oracle 基础设施，并维护分层证据；不能用一份笼统的 M1 PASS 代替后续各 owner 的验收。
- 回滚条件：若后续变更实际跨越输入、活动墨迹或稳定渲染责任边界，则把相应隔离 trace、光学或规模基线升级为该变更的前置门槛。
- 影响的需求：无；这是执行路线和证据边界澄清。

## ADR-0002：冻结 M2 前 Legacy oracle 与回归裁决规则

- 日期：2026-07-25
- 状态：accepted
- 触发证据：Legacy `DocumentBloc` 使用 `ReplayBloc`，没有 production revision，也不公开 history cursor；现有 Profile 只覆盖探针页，不能比较 Handler→Backend 所有权切换。
- 备选方案：给 Legacy 强行加入 production revision/history API；只比较最终文档；在看到 post-M2 数据后再定阈值。
- 决策：以 `legacy-elements-v1` 在真实 DocumentBloc event owner 重放固定 13 步；逐步记录规范化状态哈希、layer order、Delta、`canUndo/canRedo`，并把实际状态发射维护的 sequence revision/history position 明确标为诊断坐标。行为字段完全相等；M2-only 帧回归采用三轮百分位中位数，超过 `max(10%, 500us)` 失败，owner slice P95 超过 `max(15%, 250us)` 失败。唯一规则文件为 `artifacts/m1/M1_M2_DECISION_RULES.json`。
- 代价：F50 normalization 会增加测试时间且不能作为 timed owner slice；真实笔迹 foreground/commit/save 仍需单独真机会话观察。
- 回滚条件：若真机证明 F50 无法在当前原版稳定运行，必须在 post-M2 数据前用新 ADR 选择可稳定的代表性压力 fixture；不得事后放宽现有结果。
- 影响的需求：无；这是 M2 迁移验证合同。
