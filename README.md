# Notea

Notea 是一个面向 Android 平板与手写笔的高性能笔记项目。当前仓库处于项目基线阶段，保存冻结需求、决策记录和分阶段执行计划；产品源码尚未引入。

## 冻结基线

- 应用基线：Butterfly `v2.5.3`
- 目标设备：OPPO Pad 4 Pro / Android 16 / OPPO Pencil 2
- 演进路线：保持行为不变地抽离后端，再经过 Rust 影子执行切换到 Rust 权威后端
- 数据库：SQLite，具体 journal / synchronous 配置由真机基准决定
- 冻结需求 SHA-256：`1678bb842326cc7a1391b8c31e93b262e39f3e03abe55082b8d94d9f70790bcf`

## 文档入口

- [计划包说明](docs/README_PLAN_PACKAGE.md)
- [分步执行包](docs/ANDROID_NOTE_EXECUTION_PLAN_V1_1_0/README.md)
- [当前项目基线](docs/project-baseline/README.md)
- [M0：工具链与不可变 Butterfly 基线](docs/ANDROID_NOTE_EXECUTION_PLAN_V1_1_0/01_M0_TOOLCHAIN_AND_PRISTINE_BASELINE/EXECUTE.md)

## 当前边界

本仓库初始化只建立可追踪的文档基线。下一阶段是 M0：准备工具链、从用户 fork 锁定 Butterfly `v2.5.3`，并分别记录 AVD 与真机构建证据。在 M0 退出门槛满足前，不修改产品行为，也不引入 Rust 后端。

## 基线完整性检查

在执行包目录运行：

```sh
cd docs/ANDROID_NOTE_EXECUTION_PLAN_V1_1_0
sha256sum -c CHECKSUMS.sha256
```

冻结需求可单独检查：

```sh
sha256sum docs/project-baseline/REQUIREMENTS_BASELINE_V1.json
```

