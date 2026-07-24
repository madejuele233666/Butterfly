# 自由套索参考路线

1. 采样世界坐标套索点。
2. 使用与 zoom 相关的 RDP/距离阈值简化，但保存调试原始轨迹。
3. 自动闭合，拒绝面积过小或自交无法解释的路径。
4. 套索 AABB 查询 R-tree。
5. 对每个候选做线段与 polygon 内部/边界测试。
6. 返回稳定 ElementId 列表，排序后进入 SelectionState。
7. Renderer 仅消费 SelectionState，不成为选择真相。
