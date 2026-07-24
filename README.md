# Notea

Notea 是一个面向 Android 平板与手写笔的高性能笔记项目，以 Butterfly `v2.5.3` 为不可变产品基线，逐阶段演进到 Rust + SQLite 权威后端。

## 仓库结构

- `app/`、`api/`、`tools/`：Butterfly `v2.5.3` 产品源码及工具。
- `docs/project-baseline/`：冻结需求、决策和执行规则。
- `docs/ANDROID_NOTE_EXECUTION_PLAN_V1_1_0/`：M0–M6 分阶段执行包。
- `scripts/`：Notea 跨 WSL/Windows 的项目维护脚本。
- `artifacts/`：已记录的构建、测试和环境证据；`artifacts/local/` 仅用于本机临时输出。

## 分支契约

- `baseline/v2.5.3-pristine`：必须始终指向上游 `v2.5.3` 提交 `a10a9787fd4fdc51c9426ead83ff063136015fb2`。
- `baseline/v2.5.3-instrumented`：M1 可观测性工作的起点；初始提交与 pristine 相同。
- `work/v1-main`：Notea 主开发分支。
- `project/bootstrap-docs`：引入 Butterfly 前的文档初始化历史，只作追溯。

## 开发环境分工

- WSL `/home/madejuele/projects/Notea`：主力开发、代码修改、提交和集成。
- Windows `D:\files\Notea_Mirror\workspace`：Android/Windows 工具链、AVD、真机和构建测试。
- 两侧通过 Git 提交同步；不复制整个目录，不同步 SDK、缓存、密钥或本机临时产物。

## 文档入口

- [分步执行包](docs/ANDROID_NOTE_EXECUTION_PLAN_V1_1_0/README.md)
- [冻结项目基线](docs/project-baseline/README.md)
- [M0：工具链与不可变 Butterfly 基线](docs/ANDROID_NOTE_EXECUTION_PLAN_V1_1_0/01_M0_TOOLCHAIN_AND_PRISTINE_BASELINE/EXECUTE.md)
- [M0 实测报告与 OPPO 实机门禁](artifacts/m0/M0_REPORT.md)
- [WSL / Windows 双环境与同步协议](docs/development/DUAL_ENVIRONMENT.md)
- [Butterfly 上游项目](https://github.com/LinwoodDev/Butterfly)

## 许可证与来源

产品代码继承 Butterfly 的许可证边界：主体代码为 AGPL-3.0，`api/` 为 Apache-2.0，图像与上游文档受 `BRANDING_LICENSE` 约束。Notea 的冻结需求和执行记录不改变这些上游许可声明。
