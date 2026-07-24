# 构建模式纪律

| 模式 | 允许结论 |
|---|---|
| Debug | 功能、断点、事件流正确 |
| Profile | 帧时间、线程、I/O、native 热点 |
| Release | 最终主观跟手性和长时间稳定性 |

Debug 变慢不能证明 Release 变慢；Debug 变快也不能证明优化有效。
