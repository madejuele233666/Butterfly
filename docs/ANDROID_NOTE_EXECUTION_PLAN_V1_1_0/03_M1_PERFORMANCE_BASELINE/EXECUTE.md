# 03 / M1-B：性能与行为基线

## 目标

在第一个 M2 Handler 所有权切换前，冻结 Legacy 写操作的可重放行为 oracle，以及能发现接口层回归的最小性能基线。此阶段只加观测，不做优化，也不把完整产品性能验收提前成 M2 阻塞项。

## 构建要求

- 功能调试使用 `devDebug`；
- 正式测量使用 `devProfile`；
- 体验复核使用 `personalRelease`；
- Profile manifest 含 `<profileable android:shell="true"/>`。

## 两层基线

### M2 所有权切换门（本阶段必须）

- 空文档和一个代表性压力文档；后者优先使用能稳定重放、确实进入实际画布 owner 的 F50，若当前实现无法稳定运行则记录所用的最接近 fixture 及原因；
- 同一版本化操作序列至少重复三轮；
- 每一步保存规范化文档状态、history cursor、revision 和 created/updated/removed 集合；
- 重放由命令或 owner-boundary harness 驱动，人工操作只作交互 smoke，不作为等价性 oracle；
- 在看到 M2 后测量前冻结行为相等规则和性能回归阈值。

仓库实现入口：

- `app/lib/debug/performance/m1_legacy_oracle.dart`：Legacy event owner replay、规范化状态、Delta 和 save/reload roundtrip；
- `app/lib/debug/performance/m1_baseline_page.dart`：每轮重建干净 fixture 的真实 document canvas；
- `artifacts/m1/M1_M2_DECISION_RULES.json`：唯一行为与性能裁决规则；
- `scripts/m1_validate_oracle.py`：三轮一致性校验；
- `scripts/windows-m1.ps1 -Action prepare-m2-baseline`：离线可重复的 analyze/test/fixture/profile APK 准备门；
- `start-baseline` / `pull-baseline`：真机运行和证据拉取。

Legacy 当前没有 production revision 或公开 history cursor。oracle 中的 `sequenceRevision` 和 `historyPosition` 是根据实际状态发射维护的诊断坐标，输出必须明确标注这一语义，不能伪称为 M2 production 字段。

### 产品与技术决策基线（按需后置）

Notein/原版/当前三方对照、0/1k/10k/50k/200k 完整规模曲线、personalRelease 长时间体验、240/480 fps 光学延迟，以及六类红线全量验收，分别在 M4 发布准备、M7 活动墨迹门和 M8 稳定渲染门按触发条件执行。它们不阻塞 M2，除非 M2 实际改动了对应责任边界。

## 数据集

M2 必测空文档和一个代表性压力文档。`data/BENCHMARK_MATRIX.csv` 中的完整 0、1k、10k、50k、200k 曲线保留给后续产品与渲染决策。所有被使用的数据集都必须版本化，不能每次手工随意画一页。

## 操作轨迹

M2 的固定序列至少覆盖：

1. CreateStroke；
2. EraseStrokes；
3. PartialErase；
4. SelectByLasso + TranslateSelection；
5. Undo、Redo 与 undo 后分支；
6. 编辑后再次 CreateStroke；
7. 未完成笔迹取消且不产生稳定提交；
8. 保存、关闭和重开后的规范化状态。

性能动作必须进入真实 document canvas，并让 `stroke.commit`、`stroke.foreground.update`、`viewport.bake`、`selection.raycast`、`document.save`、`history.undo` 和 `history.redo` 中与该序列对应的 owner trace 实际出现。

自动 replay 负责 Legacy element events、undo/redo、raycast 和 bake。`stroke.foreground.update`、`stroke.commit` 与 `document.save` 必须在单独的干净 F0 Profile 会话中通过真实手写和保存触发；该人工会话只证明 owner trace 存在及其性能，不作为确定性行为 oracle。

## 采集

- Flutter DevTools frame timing；
- Android Studio System Trace/Perfetto；
- RSS；
- bake/raycast/save trace；
- 输入探针样本数；
- SQLite commit（当前原版若存在对应路径）；
- 主观笔尖距离视频仅作辅助，不替代 trace。

运行前复制 `RUN_RECORD_TEMPLATE.json`。正式基准关闭 Device Mirroring 和录屏。

## 退出门槛

- [ ] Legacy 固定序列的逐步规范化状态、history cursor、revision 和 Delta 集合已冻结；
- [ ] owner-boundary replay 可确定性重复，空文档和代表性压力文档各至少三轮；
- [ ] 对应 owner trace 在真实 document canvas 上实际出现；
- [ ] pre-M2 行为相等规则和性能回归阈值已在 post-M2 数据出现前冻结；
- [ ] 可区分活动笔画、Baking、编辑、保存和历史操作的时间；
- [ ] 基线 trace 与 APK 已归档。

## 交付物

- `artifacts/runs/` 中的 run record；
- Perfetto/Profiler 导出；
- Legacy oracle/replay 版本及规范化状态；
- 两个 fixture、每个至少三轮的指标汇总 CSV；
- `BASELINE_REPORT.md`；
- M2 优先拆分点 ADR。
