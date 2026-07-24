# Gate A：是否引入 Jetpack Ink

## 触发条件

满足任一：

- Rust 接管后，活动笔画仍超过延迟门槛；
- 原生探针证明 Flutter 丢弃历史 MotionEvent 样本；
- Profile trace 显示 foreground refresh 主导 P95/P99。

## Spike

建立独立原生 View，只实现一支笔；使用同一 OPPO 轨迹和同一设备比较 Flutter wet ink 与 Jetpack Ink。不要同时修改 dry renderer。

## 接受条件

- 端到端笔尖距离和 P99 有实质改善；
- Platform View 手势/透明叠层成本可控；
- 完成笔画能无损转换为后端 StrokeDraft；
- 不引入第二文档真相。
