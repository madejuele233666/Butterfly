# 输入探针检查表

- [x] USB ADB 稳定
- [x] USB ADB 足以完成正式采集；Wi-Fi ADB 仅作日常便利项
- [x] 原生层和 Flutter 层均有时间戳
- [x] 采集全部 historical samples
- [x] ring buffer 有容量上限并报告丢弃数
- [x] ACTION_CANCEL 被单独标记
- [x] 普通应用可见的 motion、hover、key、pressure、tilt、orientation 入口已检查
- [x] 不使用 Root 即完成第一轮
- [x] 能力报告基于 trace 而非主观判断
- [x] 未隔离的侧键/掌托业务语义没有被写成已证明
- [x] 只有进入实现范围的语义才要求逐动作独立 trace
- [x] 请求刷新率与事件实际刷新率均被记录，系统切换未被改写成纯刷新率证据

精确侧键动作归属和逐掌托顺序仍为条件式后续门，不阻塞 M2 后端边界。
