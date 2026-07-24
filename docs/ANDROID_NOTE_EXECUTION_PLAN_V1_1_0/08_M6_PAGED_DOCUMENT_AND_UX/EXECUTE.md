# 08 / M6：分页文档、直接恢复与最小工具栏

## 目标

完成冻结 V1：创建时分页/无限二选一、启动直接恢复、Notein 思路参考的高效率工具栏。不得在本阶段加入 PDF、AI、同步等 Deferred 功能。

## 分页实现

- Infinite：一个无界 Space；
- Paged：多个固定边界 Page Space；
- 两者共享 Element、Command、Geometry、Undo、SQLite；
- V1 不允许跨页元素；
- 只保留当前页、相邻页和小范围预取的渲染资源；
- 页面缩略图异步生成，不能阻塞书写事务。

## 直接恢复

应用级 library/session 数据保存：

- last document ID/path；
- active space/page；
- camera transform；
- persistent tool；
- brush settings；
- clean shutdown marker。

启动先显示可交互壳层，再异步打开文档；若恢复失败，明确展示错误并允许选择备份，不静默新建空白文档覆盖路径。

## 工具栏

只包含 V1 高频操作：

- 压力笔；
- 整笔/局部橡皮模式；
- 套索；
- undo/redo；
- 当前笔宽/颜色；
- 页面/无限模式的导航入口。

侧键临时工具由 PersistentTool + TemporaryToolStack 实现，不能覆盖用户持久选择。工具栏借鉴 Notein 的操作密度和就近参数，但不复制视觉资产或层级。

## 退出门槛

- [ ] 创建时模式二选一；
- [ ] 100 页文档只虚拟化可见附近页面；
- [ ] 启动恢复文档/页面/视角/工具；
- [ ] 恢复失败不会覆盖数据；
- [ ] 工具切换不超过冻结交互层级；
- [ ] V1 全功能通过 Release 长时间使用。
