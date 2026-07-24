# 00：项目基线与漂移防护

## 开始条件

无。这是所有工作的入口。

## 必做

1. 阅读 `REQUIREMENTS_BASELINE_V1.json`，确认它与当前理解一致。
2. 校验 SHA-256：`1678bb842326cc7a1391b8c31e93b262e39f3e03abe55082b8d94d9f70790bcf`。
3. 阅读 `DECISION_FREEZE.md` 和 `EXECUTION_RULES.md`。
4. 在仓库中建立 `docs/project-baseline/`，复制本目录内容。
5. 提交一次只包含文档的 baseline commit。

## 退出门槛

- [ ] 需求文件 hash 一致；
- [ ] Butterfly `v2.5.3` 和目标硬件已写入仓库文档；
- [ ] 所有人都知道 Root、Jetpack Ink 和 Tile Cache 均不是既定前提；
- [ ] 后续变更有明确记录位置。

## 交付物

- `baseline-docs` Git commit；
- `DECISION_LOG.md` 初始副本；
- 需求 hash 检查结果。
