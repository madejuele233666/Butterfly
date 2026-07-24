# 04 / M2：抽离 Legacy 后端边界，不改变行为

## 目标

把现有 Handler → DocumentBloc 直接修改变成 Handler → Command → DocumentBackend → Delta。权威状态仍是 Legacy Dart；本阶段性能不应显著改善，也不应显著退化。

## 为什么先做这一步

直接把 Rust 或 SQLite 塞入 DocumentBloc，会保留原有耦合，并产生两个隐式真相源。必须先建立可替换边界，才可能进行可验证迁移。

## 步骤

1. 复制 `interfaces/DocumentBackend.dart` 到项目设计目录并按当前代码调整。
2. 定义 V1 命令 DTO：CreateStroke、EraseStrokes、PartialErase、TranslateSelection、Undo、Redo。
3. 定义稳定 `DocumentDelta`：created/updated/removed IDs、dirty bounds、revision、history cursor。
4. 实现 `LegacyDartBackend`，内部调用原 DocumentBloc 行为。
5. 逐个 Handler 改为只发命令，不直接构造 `ElementsCreated/Changed/Removed`。
6. 选择状态从 `Renderer` 集合改成 ElementId 集合；M2 可先适配器包装，不一次完成几何迁移。
7. 建立 golden/parity 测试，确保规范化状态与基线一致。
8. 比较 M1 trace，确认接口层没有引入明显 P99 回归。

## 提交顺序

- Commit 1：DTO 与接口，无调用方修改；
- Commit 2：Legacy backend adapter；
- Commit 3：Pen Handler；
- Commit 4：整笔擦除；
- Commit 5：局部擦除；
- Commit 6：选择/移动；
- Commit 7：undo/redo；
- Commit 8：删除不再使用的直接入口。

每个提交独立通过测试，禁止一个大提交同时迁移所有 Handler。

## 退出门槛

- [ ] UI/Handler 不直接写元素集合；
- [ ] 所有 V1 写操作有命令 DTO；
- [ ] Legacy backend 是唯一真相；
- [ ] Delta 足以同步渲染器，不需返回完整文档；
- [ ] 固定操作轨迹行为一致；
- [ ] M1 指标无不可解释回归。
