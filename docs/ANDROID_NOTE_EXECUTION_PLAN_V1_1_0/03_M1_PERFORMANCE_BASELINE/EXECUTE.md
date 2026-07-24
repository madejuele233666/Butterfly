# 03 / M1-B：性能与行为基线

## 目标

在任何架构修改前，把 Notein 痛点和 Butterfly 现状转换为可重复数字。此阶段只加观测，不做优化。

## 构建要求

- 功能调试使用 `devDebug`；
- 正式测量使用 `devProfile`；
- 体验复核使用 `personalRelease`；
- Profile manifest 含 `<profileable android:shell="true"/>`。

## 数据集

使用 `data/BENCHMARK_MATRIX.csv` 生成或保存固定文档：0、1k、10k、50k、200k 笔画。数据集必须版本化，不能每次手工随意画一页。

## 操作轨迹

每个数据集执行：

1. 连续写 30 秒；
2. 快速小字与长线；
3. 平移和缩放；
4. 整笔擦除 20 秒；
5. 局部擦除 20 秒；
6. 套索 500 笔并移动；
7. undo/redo 各 100 次；
8. 编辑后再连续写 30 秒；
9. 关闭并冷启动恢复。

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

- [ ] 六类性能红线均有至少一项量化指标；
- [ ] 空白、1k、10k、50k 数据齐全；
- [ ] 能重现至少一个 Notein/Butterfly 长期卡顿场景或明确说明未重现；
- [ ] 可区分活动笔画、Baking、编辑、保存和打开的时间；
- [ ] 基线 trace 与 APK 已归档。

## 交付物

- `artifacts/runs/` 中的 run record；
- Perfetto/Profiler 导出；
- 指标汇总 CSV；
- `BASELINE_REPORT.md`；
- M2 优先拆分点 ADR。
