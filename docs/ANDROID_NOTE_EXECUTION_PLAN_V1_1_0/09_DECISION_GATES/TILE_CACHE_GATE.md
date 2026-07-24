# Gate B：是否替换 Butterfly Baking

## 触发条件

必须先在真实 document canvas、同 fixture/replay 的 Profile 对照中，把首个超标位置归因到 stable renderer/bake owner，并确认 dirty bounds 已正确。随后满足任一：

- 稳定内容 bake 在 10k/50k 文档中持续主导掉帧；
- 编辑后 full rebake 造成不可接受暂停；
- 可见区域和 dirty bounds 已正确，但单大图缓存仍成为瓶颈。

仅有总帧 P99、内存增长或编辑后卡顿不足以触发；输入、命令、DB、几何和错误的全量失效由各自 owner 修复。

## Spike

实现小范围 tile cache，只覆盖无限画布稳定 Stroke；不要同时迁移分页和 Jetpack Ink。

## 接受条件

- pan/zoom P99 改善；
- dirty tile 数随局部操作有界；
- 内存和纹理数量可控；
- tile 缺失有明确占位，不阻塞输入。
- 对照阈值在 Spike 数据出现前冻结；若无清晰收益，保留 Baking。
