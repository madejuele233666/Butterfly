# 局部橡皮擦参考路线

1. 把橡皮相邻采样形成 swept capsule。
2. 用 capsule AABB 查询 R-tree 候选 Stroke。
3. 对候选笔画线段求进入/离开参数 t。
4. 在 t 处生成插值点：x/y/pressure/time/tilt。
5. 生成非空、至少满足最小长度的片段。
6. 原 stroke 删除，片段使用新 ID；逆命令保存原 stroke。
7. 一次橡皮手势结束时统一事务提交。

属性测试：擦除区域外几何保持；片段顺序保持；undo 精确恢复原始 payload。
