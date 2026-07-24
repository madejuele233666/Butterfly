# Gate A：是否引入 Jetpack Ink

## 触发条件

先用同 fixture/replay、当前 Flutter active path 的 Profile trace 和必要的光学录像定位首个超标 owner，再满足任一：

- Rust 接管后，活动笔画仍超过延迟门槛；
- 原生探针证明 Flutter 丢弃历史 MotionEvent 样本；
- Profile trace 显示 foreground refresh 主导 P95/P99。

总帧变慢、stable bake、DB、几何或错误的全量失效不是本门的触发证据。侧键和掌托精确语义只在 Spike 改变其路由时才是前置条件。

## Spike

建立独立原生 View，只实现一支笔；使用同一 OPPO 轨迹和同一设备比较 Flutter wet ink 与 Jetpack Ink。不要同时修改 dry renderer。

## 接受条件

- 端到端笔尖距离和 P99 有实质改善；
- Platform View 手势/透明叠层成本可控；
- 完成笔画能无损转换为后端 StrokeDraft；
- 不引入第二文档真相。
- 对照规则和阈值在 Spike 结果出现前冻结；若无清晰收益，结论为保留 Flutter，而不是继续扩张原生层。
