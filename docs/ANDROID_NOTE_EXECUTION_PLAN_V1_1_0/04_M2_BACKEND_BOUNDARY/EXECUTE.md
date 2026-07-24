# 04 / M2：抽离 Legacy 后端边界，不改变行为

## 目标

把现有 Handler → DocumentBloc 直接修改变成 Handler → Command → DocumentBackend → Delta。权威状态仍是 Legacy Dart；本阶段性能不应显著改善，也不应显著退化。

## 为什么先做这一步

直接把 Rust 或 SQLite 塞入 DocumentBloc，会保留原有耦合，并产生两个隐式真相源。必须先建立可替换边界，才可能进行可验证迁移。

## 开始门与所有权切换门

DTO/接口和尚未接管调用方的 `LegacyDartBackend` 是加法变更，可在 M1 输入事实建立后开始。第一个 Handler 改为发送 Command 前必须具备：

1. 覆盖 CreateStroke、EraseStrokes、PartialErase、TranslateSelection、Undo、Redo、取消不提交和保存重开的 Legacy oracle；
2. 每一步的规范化状态、history cursor、revision 和 created/updated/removed 集合；
3. 确定性的 owner-boundary replay；
4. 空文档和代表性压力文档各至少三轮的 pre-M2 `devProfile` 基线；
5. 预先冻结的行为相等规则与性能回归阈值。

独立的十二项 Pencil trace、纯 60 Hz 双指场景、Wi-Fi ADB、Notein 三方对照、完整规模曲线、personalRelease 和光学录像不属于本阶段切换门，除非本阶段代码实际改变了这些责任边界。

## 步骤

1. 复制 `interfaces/DocumentBackend.dart` 到项目设计目录并按当前代码调整。
2. 定义 V1 命令 DTO：CreateStroke、EraseStrokes、PartialErase、TranslateSelection、Undo、Redo。
3. 定义稳定 `DocumentDelta`：created/updated/removed IDs、dirty bounds、revision、history cursor。
4. 实现 `LegacyDartBackend`，内部调用原 DocumentBloc 行为。
5. 逐个 Handler 改为只发命令，不直接构造 `ElementsCreated/Changed/Removed`。
6. 选择状态从 `Renderer` 集合改成 ElementId 集合；M2 可先适配器包装，不一次完成几何迁移。
7. 用同一 owner-boundary replay 建立 golden/parity 测试，逐命令比较规范化状态、history cursor、revision 和 Delta 集合。
8. 在相同 fixture、操作版本和运行条件下比较冻结的 M1 指标，按预先定义的规则裁决回归。

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
- [ ] Legacy oracle 的逐步规范化状态、history cursor、revision 和 Delta 集合一致；
- [ ] 定向 M1 指标按冻结规则无不可解释回归。
