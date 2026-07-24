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
