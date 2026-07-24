# 性能基线报告

## 环境

- Commit：
- Device fingerprint：
- Build variant：
- Refresh rate：
- Root：
- Mirroring/recording：

## M2 所有权切换门

- Legacy oracle/replay 版本：
- 覆盖命令：CreateStroke / EraseStrokes / PartialErase / TranslateSelection / Undo / Redo / cancel-no-commit / save-reload
- 逐步规范化状态、history cursor、revision 与 Delta artifact：
- 空文档 hash 与至少三轮 run ID：
- 代表性压力文档 hash 与至少三轮 run ID：
- 预冻结行为相等规则：
- 预冻结性能回归规则：
- 实际出现的 owner trace：

## 指标

| 场景 | UI P95 | Raster P95 | P99 | RSS | 主观观察 | Trace |
|---|---:|---:|---:|---:|---|---|
| 空白写字 | | | | | | |
| 代表性压力文档写字 | | | | | | |
| pan/zoom | | | | | | |
| 擦除后写字 | | | | | | |
| 套索后写字 | | | | | | |
| undo 后写字 | | | | | | |

## 第一错误事实

描述最早出现的错误/延迟事实，而不是只写最终“卡顿”。

## M2 建议优先边界

- 证据：
- 拆分点：
- 不应同时改变的模块：

## 后置产品/决策门证据

Notein/原版/当前三方对照、完整规模曲线、personalRelease 和光学录像只在
M4 发布准备、M7 活动墨迹或 M8 stable renderer 门触发时补充。
