# 规范化状态

比较前：

1. 元素按稳定 ID 排序；
2. 颜色和数值使用统一表示；
3. float 仅在明确算法差异允许时量化；
4. 旧 Butterfly 点缺失 timestamp/tilt，统一为 None；
5. 排除纯渲染缓存；
6. 不排除 bounds、transform、pressure、history cursor。

任何新增 ignore field 必须有 ADR。
