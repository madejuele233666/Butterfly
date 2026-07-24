# Android 高性能手写笔记软件：Butterfly → Rust 后端渐进式重构主计划

> 文档状态：**Frozen Baseline + Executable Plan**  
> 版本：**1.1.1**
> 日期：**2026-07-25**
> 目标设备：**OPPO Pad 4 Pro / Android 16 / 120 Hz / OPPO Pencil 2**  
> 主项目路线：**Fork Butterfly，保持行为不变地抽离前后端，再让 Rust 后端逐项接管**  
> 需求基线文件：`REQUIREMENTS_BASELINE_V1.json`  
> 需求基线 SHA-256：`1678bb842326cc7a1391b8c31e93b262e39f3e03abe55082b8d94d9f70790bcf`

---

## 0. 本文档如何使用

本文档同时承担四种职责：

1. **需求冻结**：保存用户最初动机、两轮 Grill 原始问题和正式回答，防止后续迭代把“想做什么”悄悄替换成“当前代码容易做什么”。
2. **技术裁决**：记录为什么选择 Butterfly 作为完整应用基线，为什么选择 Rust 作为目标后端，以及为什么不立刻把 Jetpack Ink 当作必选项。
3. **可执行计划**：将第一版附近的每个功能拆成明确的数据结构、调用链、算法、迁移步骤、测试和验收条件。
4. **变更控制**：任何后续修改都必须区分“需求变更”“实现变更”和“调研事实更新”，不能直接覆盖原始答案。

### 0.1 事实、推断与决策的标记

- **证据**：来自固定版本源码、官方文档、真机测量或可复现测试。
- **推断**：由证据导出的工程判断，仍可能被实验推翻。
- **决策**：当前计划采用的路线；如需改变，必须写入决策日志。
- **门槛**：只有满足量化条件才能进入下一阶段。

### 0.2 对“第一版没有明确非目标”的解释

原始回答中“第一版明确不允许加入的内容”为“无”。这**不等于第一版包含所有功能**。结合用户同时提出的“功能依旧保留第一版附近”“其余选项也逐步实现，只是本轮不实现”，本文采用如下解释：

> 没有永久禁止的功能；但 V1 范围冻结在本文件列出的功能。未入选功能属于 Deferred，不得未经需求版本升级进入 V1。

### 0.3 修订记录

| 版本 | 日期 | 变更类型 | 内容 |
|---|---|---|---|
| 1.0.0 | 2026-07-24 | 初始基线 | 冻结原始需求、两轮 Grill 回答、Butterfly → Rust 渐进式重构计划。 |
| 1.0.1 | 2026-07-24 | 调研事实与实现决策更新 | **保留 SQLite，不引入 redb**；取消“WAL + NORMAL 是既定答案”的假设；重写 SQLite schema、日志模式决策、checkpoint 调度、备份、完整性检查、维护和故障测试要求。需求基线未变化。 |
| 1.1.0 | 2026-07-24 | 开发执行与文档工程更新 | 整合 Windows/Android Studio/AVD/真机无线联调、Debug/Profile/Release 构建、OPPO Pencil 2 输入探针、性能工具和 Root 诊断边界；新增按门槛切片的可执行阶段文档包。需求基线未变化。 |
| 1.1.1 | 2026-07-25 | 第一性原理门槛收敛 | 依据当前真机证据，把 M1→M8 门槛改为 owner-specific oracle/replay/切换规则；完整产品矩阵移到对应发布或技术决策门。需求基线未变化。 |

---

# 第一部分：需求冻结

## 1. 原始动机（原文保留）

- “我想开发一个Android平板的笔记软件，支持手写笔。进行前期市场调研，以及参考开源代码的思路。开发动机：我期望实现一个可自定义的笔记软件，可以自己加功能而不用等待商业软件缓慢更新”
- “我完全可以开源发布，我甚至可以不发布，只自己使用”
- “从性能和使用体验来分析各软件的内核质量，选取最适合fork的项目
从第一性原理出发思考”
- “使用grill全面了解我的开发需求”
- “深度grill，同时深度搜索资料和调研，输出一份详细的计划（注：这里的详细并不是功能多，功能依旧保留第一版附近的功能。这里的详细是每个功能给出详细的参考实现路线。同时保留我的原始需求和原始问答，防止后续迭代文档时逐渐飘移）”

## 2. 不可替换的产品目标

### 2.1 产品不是“另一个功能更多的笔记软件”

核心目标是：

> 在保留用户常用 Notein 类书写与编辑能力的前提下，消除长期使用、满页、大文档和编辑操作后的持续卡顿，并建立可由用户自行扩展的清晰内部架构。

因此，功能数量不是主要评价指标。V1 成功的定义首先是：

- 笔迹不明显落后笔尖；
- 快速书写不丢样本、不产生明显形变；
- 页面笔画增加后，实时书写成本不随历史笔画数线性恶化；
- 橡皮擦、套索和撤销之后不进入持续低性能状态；
- Rust 后端与 Flutter 前端边界清晰，新增工具不需要侵入多个核心模块。

### 2.2 固定产品边界

| 维度 | 冻结结论 |
|---|---|
| 用户范围 | 仅供自己使用 |
| 硬件 | OPPO Pad 4 Pro、Android 16、120 Hz、OPPO Pencil 2 |
| 兼容性 | 不为其他设备主动承担兼容成本 |
| 基础代码 | Butterfly Fork |
| 重构方法 | 保持行为不变地抽离接口 → 双后端影子执行 → Rust 接管 |
| 主要后端 | Rust |
| UI/现成能力 | 初期保留 Flutter/Butterfly |
| 数据 | **SQLite 嵌入式事务**；数据库引擎固定，journal/synchronous 组合由真机基准裁决 |
| 文档模式 | 每个文档创建时选择“无限画布”或“分页” |
| 最小原型 | 无限画布、单支笔、基础书写与擦除 |
| 性能与速度冲突 | 性能优先 |
| 扩展方式 | 内部模块与注册表，重新编译；暂不做动态第三方插件 |

## 3. V1 功能范围

### 3.1 V1 必须完成

1. 无限画布文档。
2. 分页文档；创建时与无限画布二选一。
3. 单一压力钢笔。
4. 笔迹平滑/稳定强度可调。
5. 手写笔负责书写；手指只负责平移与缩放。
6. OPPO Pencil 2 快捷动作切换橡皮擦；若硬件只暴露双击而不暴露按下/松开，则必须明确记录硬件限制，不能伪装成“按住临时切换”。
7. 整笔画橡皮擦。
8. 局部像素式橡皮擦。
9. 自由套索。
10. 选区移动。
11. 每次完整落笔作为一个撤销单位；一次橡皮手势、一次选区移动也分别形成单一事务。
12. 启动直接恢复上次文档、视角和工具状态。
13. 嵌入式数据库事务与崩溃一致性。
14. 最小化、Notein 思路参考的工具栏与工具切换体验。
15. 性能基准、回归测试和可观测性属于 V1 基础设施，不是可选工作。

### 3.2 Deferred：本轮不实现，但不是永久禁止

- 选区缩放、旋转；
- 剪切、复制、粘贴；
- 圆珠笔、荧光笔和多笔预设；
- PDF；
- 图片、文本、Markdown、公式；
- 云同步、WebDAV、多设备；
- OCR、AI、录音；
- 第三方动态插件；
- 协作、跨平台优化；
- 面向商店发布的广泛兼容与恢复兜底。

---

# 第二部分：调研结论与技术裁决

## 4. 为什么以 Butterfly 2.5.3 为固定基线

### 4.1 版本选择

**证据**：Butterfly 官方把 2.5.3 标为 2026-06-08 的稳定版本；其版本策略将稳定版与 nightly/develop 分离。Butterfly 2.6.0-beta.2 在 2026-07-13 明确进行了“整个状态管理结构重构”。

**决策**：

- 从精确 tag `v2.5.3` 建立不可变基线；
- 不从 moving `main` 或 2.6 beta 启动；
- 上游只选择性移植孤立的 Android、输入、安全或崩溃修复；
- 不在本项目拆后端的同时合并上游同一区域的状态管理大重构。

这样不是拒绝上游，而是避免同时进行两次互不协调的系统迁移。

### 4.2 Butterfly 已有的正确内核方向

Butterfly 2.5.3 已经将：

- 活动内容放在 `ForegroundPainter`；
- 稳定内容绘制为 baked image；
- 当前帧只逐元素绘制 `visibleUnbakedElements`；
- `CameraViewport` 显式维护 baked、unbaked、visible 和 visible-unbaked 集合。

这说明它的内核方向不是“每帧遍历整份历史内容”。相关源码：

- `app/lib/view_painter.dart:L19-L77, L149-L242`
- `app/lib/models/viewport.dart:L16-L79, L204-L273`

### 4.3 Butterfly 当前的结构性债务

1. `DocumentBloc` 同时连接文档状态、历史、文件系统、CurrentIndex、渲染器和网络，职责过重。
2. 选择状态直接持有 `Renderer<PadElement>`，使文档语义依赖渲染对象。
3. `PenHandler` 在 Flutter PointerMoveEvent 上逐事件追加一个点，没有原生 MotionEvent 历史样本入口。
4. 当前 `PathPoint` 只保存 x/y/pressure，没有时间戳、倾角、方向和样本来源。
5. 当前局部橡皮擦只删除落入圆内的离散原始点，然后把剩余点序列切段；它不是连续线段或笔画轮廓意义上的几何切割。
6. 当前整笔画橡皮擦、套索、撤销和 Baking 之间曾出现“操作后持续卡顿”的真实回归。

这些债务决定了迁移顺序：

> 先把文档行为从 Renderer/Bloc 中抽出，建立可验证的纯后端协议；然后才让 Rust 接管。不能先把 SQLite 或 Rust 塞进现有 Bloc，再继续让所有模块直接操作它。

## 5. Jetpack Ink 的定位

### 5.1 不作为起点的原因

用户明确选择 Butterfly 主仓库渐进式重构。若立刻把 Flutter 画布换成原生 Jetpack Ink，会同时引入：

- Platform View 或原生覆盖层；
- Flutter 与 Android 手势竞争；
- 两套相机变换同步；
- wet stroke 与 dry stroke 视觉一致性；
- 原生 Stroke 与 Butterfly PenElement 的转换；
- HCPP 透明叠层限制。

这会让“后端抽离是否正确”和“原生画布是否正确”无法独立验证。

### 5.2 作为性能决策门的价值

Jetpack Ink stable 1.0.0 已提供：

- `InProgressStrokesView` 的低延迟活动墨迹；
- MotionEvent 输入、预测事件和完成笔画回调；
- Brush、Stroke、Geometry、Rendering、Storage 模块；
- `eagerInit()` 与 unbuffered dispatch 建议。

因此计划保留 **Native Ink Spike**，但触发条件是：

1. Rust 后端接管后，Flutter 活动笔迹仍无法达到延迟门槛；或
2. 真机日志证明 Flutter 路径丢失 MotionEvent 历史批次；或
3. 120 Hz 下 P95/P99 帧时间仍被活动笔迹前景刷新主导。

Jetpack Ink 1.1.0-alpha05 的 partial-stroke eraser仍缺切口抗锯齿和结果序列化，不能成为 V1 数据真相源。

## 6. OPPO Pencil 2 的已知与未知

官方公开页面只明确列出 OPPO Pencil 2 的“快捷按键”，而上一代 OPPO Pencil 页面描述了双击切换、240 Hz、4096 压感和厂商局部刷新 SDK。**这些不能直接证明 Pencil 2 在普通 Android 应用中会暴露 BUTTON_DOWN/BUTTON_UP。**

因此，侧键功能前必须完成设备能力探针。若只得到一次“双击动作”，则物理上无法实现“按住临时切换、松开恢复”；此时应把需求记录为硬件阻塞，而不是在代码里静默改成某种替代语义。

---

# 第三部分：目标架构

## 7. 迁移完成后的职责边界

```text
┌──────────────── Flutter UI / Butterfly shell ────────────────┐
│ 工具栏、导航、页面列表、对话框、前景预览、相机手势           │
│ 不直接修改文档；只发送 Command，接收 DocumentDelta            │
└──────────────────────────┬────────────────────────────────────┘
                           │ coarse-grained async FFI
┌──────────────────────────▼────────────────────────────────────┐
│ Rust Document Backend（权威状态）                              │
│ DocumentSession actor                                         │
│ Command / Undo / Geometry / R-tree / Validation / DB          │
└───────────────┬──────────────────────┬─────────────────────────┘
                │                      │
┌───────────────▼───────────┐  ┌──────▼─────────────────────────┐
│ SQLite per-document DB     │  │ Flutter stable renderer        │
│ transaction/history/backup │  │ 初期复用 Butterfly Baking      │
└────────────────────────────┘  │ 后续按门槛决定 tile / native Ink│
                                └─────────────────────────────────┘
```

### 7.1 核心原则

1. **活动笔画不逐点跨 FFI。** 前端收集和显示活动笔画；抬笔后一次提交完整 `StrokeDraft`。
2. **文档写操作全部命令化。** UI、侧键、工具和手势都不能直接修改元素列表。
3. **Rust 单写者模型。** 一个 `DocumentSession` actor 独占可变文档状态、内存 R-tree 和 SQLite writer connection。
4. **渲染器不是文档对象。** 选择、橡皮擦和撤销只操作 ElementId 与几何数据。
5. **前端只接收增量。** 每个命令返回 `DocumentDelta`，不得每次返回整份文档。
6. **外部数据只在边界验证。** 数据库读入、Butterfly 导入、FFI 参数和 Android 输入转化完成后，内部对象必须满足不变量。
7. **未知状态明确失败。** 不注册的元素类型、未知文件版本、索引不一致不能静默退化成默认元素。

## 8. Rust workspace 建议

```text
rust/
├── Cargo.toml
├── crates/
│   ├── note_core/        # Document、Element、Command、Delta、不变量
│   ├── note_geometry/    # hit test、lasso、eraser、bounds
│   ├── note_index/       # rstar R-tree 与 viewport query
│   ├── note_storage/     # SQLite schema、migration、transaction、backup、integrity
│   ├── note_compat/      # Butterfly 2.5.3 导入/导出与规范化
│   ├── note_backend/     # DocumentSession actor、undo/redo、协调
│   └── note_bridge/      # flutter_rust_bridge 暴露层
└── tests/
    ├── fixtures/
    ├── parity/
    ├── geometry/
    └── performance/
```

### 8.1 Dart 侧接口

```dart
abstract interface class DocumentBackend {
  Future<BackendSession> open(OpenDocumentRequest request);
  Future<DocumentDelta> apply(CommandDto command);
  Future<DocumentDelta> undo();
  Future<DocumentDelta> redo();
  Future<ViewportSnapshot> queryViewport(ViewportQuery query);
  Future<HitTestResult> hitTest(HitTestQuery query);
  Stream<BackendEvent> get events;
  Future<void> checkpoint();
  Future<void> close();
}
```

最初提供两个实现：

```text
LegacyDartBackend  -> 包装现有 DocumentBloc 行为
RustShadowBackend  -> 同时调用 Legacy 与 Rust，只以 Legacy 为真相并比较结果
```

最终：

```text
RustAuthoritativeBackend -> Rust 为真相；Flutter 只维护 ViewModel/Renderer cache
```

### 8.2 Rust 桥接口必须粗粒度

```rust
pub async fn open_document(req: OpenDocumentRequest) -> Result<DocumentSession>;
pub async fn apply_command(session: &DocumentSession, cmd: Command) -> Result<DocumentDelta>;
pub async fn query_viewport(session: &DocumentSession, q: ViewportQuery) -> Result<ViewportSnapshot>;
pub async fn undo(session: &DocumentSession) -> Result<DocumentDelta>;
pub async fn redo(session: &DocumentSession) -> Result<DocumentDelta>;
```

禁止的接口形态：

```rust
append_pointer_sample(x, y, pressure)
```

原因：每个采样点跨 FFI 会把实时路径绑定到桥接调度、序列化和锁竞争；它没有必要。

## 9. 目标文档模型

```rust
pub enum DocumentMode {
    Infinite,
    Paged { page_width: f64, page_height: f64, gap: f64 },
}

pub struct Document {
    pub id: DocumentId,
    pub mode: DocumentMode,
    pub spaces: SlotMap<SpaceId, Space>,
    pub elements: SlotMap<ElementId, Element>,
    pub revision: u64,
}

pub enum SpaceKind {
    InfiniteCanvas,
    Page { index: u32 },
}

pub struct ElementHeader {
    pub id: ElementId,
    pub space_id: SpaceId,
    pub z_order: i64,
    pub transform: Affine2,
    pub bounds: Aabb,
    pub revision: u64,
}

pub enum Element {
    Stroke(StrokeElement),
    // 其他类型保留兼容入口，但 V1 不扩展其能力
}
```

### 9.1 为什么不用“无限世界里的 PageFrame”作为 V1 主模型

深度 Grill 已决定“每个文档创建时二选一”。Butterfly 本身也以多个 `DocumentPage` 表示页面。V1 采用：

- 无限文档：一个无界 Space；
- 分页文档：多个固定边界 Page Space；
- 共享 Element、Command、Geometry、Undo 和 Storage；
- 不允许跨页元素。

这比把所有页面塞进同一个无限坐标世界更接近现有 Butterfly 行为，也更容易完成行为等价迁移。未来若加入跨页书写，再通过新需求版本引入世界级 PageFrame。

## 10. Stroke 数据模型

```rust
pub struct RawStrokePoint {
    pub x: f64,
    pub y: f64,
    pub pressure: f32,
    pub elapsed_micros: u32,
    pub tilt: Option<f32>,
    pub orientation: Option<f32>,
    pub flags: PointFlags,
}

pub struct StrokeElement {
    pub header: ElementHeader,
    pub brush: BrushSpec,
    pub raw_points: Arc<[RawStrokePoint]>,
    pub render_cache_key: u64,
}
```

原则：

- 原始样本是事实，不能被平滑算法覆盖；
- 平滑后的路径、轮廓、多边形和 tile 都是可重建缓存；
- 旧 Butterfly `PathPoint(x,y,pressure)` 导入时，时间戳与倾角为空；
- 新笔画保留历史 MotionEvent 样本；
- 巨大无限坐标下，可在二进制点块中采用“f64 局部原点 + f32 相对坐标”，但内存计算仍使用 f64。

---


# 第三部分补充：开发环境、真机联调与 Root 策略

## E1. 第一性原理：不同环境只能证明不同事实

本项目需要同时使用模拟器和 OPPO Pad 4 Pro，但二者的职责不能混淆：

| 环境 | 能证明的事实 | 不能证明的事实 |
|---|---|---|
| PC 纯 Rust 测试 | 命令、几何、序列化、SQLite 事务的确定性 | Android 调度、触控笔、GPU 和闪存尾延迟 |
| Android AVD | UI、路由、生命周期、迁移、恢复和自动测试是否正确 | OPPO Pencil 2 事件、120 Hz 跟手性、掌托和真实 I/O |
| OPPO 真机 Debug | 输入事件是否被正确识别，功能是否可交互 | 最终帧时间和端到端延迟 |
| OPPO 真机 Profile | 接近发布配置的帧时间、线程、I/O 和 native 热点 | 完全无观测开销的最终体验 |
| OPPO 真机 Release | 最终使用体验和长时间稳定性 | 深度调用栈和调试状态 |
| Root 真机 | Linux 输入节点和厂商服务等更深层证据 | 普通非 Root 应用一定能够获取同样事件 |

因此采用以下纪律：

1. **模拟器用于逻辑真相，真机用于产品真相。**
2. **Debug 用于定位，Profile 用于量化，Release 用于裁决。**
3. **Root 只扩大观测范围，不作为 V1 运行依赖。**
4. **任何性能结论必须注明设备、构建模式、镜像/录屏状态、温度和测试数据集。**

## E2. Windows 主工具链与 WSL 边界

推荐把 Android 主工具链统一安装在 Windows 宿主：

```text
Windows
├── Android Studio stable
├── Android SDK Platform / Build Tools / Platform Tools
├── Android Emulator
├── Flutter 3.44.1（Butterfly 2.5.3 固定版本）
├── Rust stable + aarch64-linux-android target
├── Android NDK + CMake
└── Git

WSL
├── 纯 Rust 单元/属性测试
├── Python 基准分析
└── 非 Android 的命令行处理
```

第一阶段不要把 Android Studio、ADB server、模拟器和 APK 主构建迁入 WSL。否则会同时引入 USB 转发、两套 ADB、Windows/WSL 路径转换和跨文件系统 Gradle I/O，增加与产品无关的变量。

### E2.1 固定工具版本

Butterfly `v2.5.3` 的 `app/pubspec.yaml` 固定 Flutter 3.44.1。M0 必须记录：

```text
Android Studio build
JDK version
Flutter / Dart version
Android SDK path
Platform Tools version
NDK version
Rust / Cargo version
Git commit and tag
Windows build
OPPO system build fingerprint
```

这些信息写入 `toolchain-lock.env` 和每次基准的 run record。

## E3. Android Studio、SDK 与模拟器

安装 Android Studio stable，并在 SDK Manager 中安装：

- Android SDK Platform 36；
- Build-Tools；
- Platform-Tools；
- Command-line Tools；
- Android Emulator；
- NDK (Side by side)；
- CMake。

只创建一个主 AVD：

```text
Name: NoteDev_API36_Tablet
Device: Pixel Tablet 或相近大屏 tablet profile
System image: API 36 AOSP x86_64
Graphics: Hardware / Auto
RAM: 4096–8192 MB
Storage: 16 GB
```

使用 AOSP 镜像是为了获得更清晰的设备文件访问和更少的 Play 服务噪声。模拟器必须启用 VM 与图形硬件加速；Windows 优先使用 Windows Hypervisor Platform。

### E3.1 模拟器职责

模拟器负责：

- Flutter UI、工具栏、路由和启动恢复；
- 文档创建与模式选择；
- SQLite schema、migration、备份恢复；
- Rust/Dart parity 自动测试；
- undo/redo、命令事务和故障注入；
- 横竖屏、窗口尺寸和进程重启；
- CI 中可重复的 instrumented smoke test。

模拟器不得用于裁决：

- 笔尖到墨迹距离；
- OPPO Pencil 2 压力和侧键；
- 掌托拒绝；
- 120 Hz 帧稳定性；
- 真机 SQLite P99；
- GPU Baking、温控和功耗。

## E4. 真机连接与三个构建变体

第一次使用 USB 连接并完成 RSA 授权：

```powershell
adb devices -l
flutter devices
flutter run -d <device-id>
```

日常开发可以使用 Android 11+ 的无线调试，通过 Android Studio 的 `Pair Devices Using Wi-Fi` 完成配对。无线调试适合热重载和功能联调；正式基准优先 USB，以减少网络波动和设备镜像干扰。

### E4.1 构建变体

至少维护三个互不覆盖数据的应用变体：

| 变体 | 用途 | 约束 |
|---|---|---|
| `devDebug` | 热重载、断点、事件探针、影子执行 | 不用于性能裁决 |
| `devProfile` | DevTools、Perfetto、System Trace、Simpleperf | 基于 release 优化，启用 `<profileable android:shell="true"/>` |
| `personalRelease` | 日常真实使用和最终体验 | 关闭探针与高频日志 |

三个变体应使用不同 applicationId 和数据库目录，使原始 Butterfly、开发版和个人日用版可以同时安装。

### E4.2 性能测试环境纪律

正式 Profile/Release 基准时关闭：

- Android Studio Device Mirroring；
- scrcpy 或其他实时镜像；
- 屏幕录制；
- Layout Inspector；
- 高频 Logcat；
- debug assertions 和 shadow diff；
- 非必要后台应用。

记录电量、温度、刷新率设置和性能模式。相同实验必须使用相同条件。

## E5. OPPO Pencil 2 原生输入探针

在修改 Butterfly 的笔处理前，先建立 Android 原生输入探针。探针在 `dispatchTouchEvent()`、`onGenericMotionEvent()` 和必要的 `dispatchKeyEvent()` 中采集，但不能每个事件同步写磁盘或刷 Logcat；应写入固定容量内存 ring buffer，测试完成后一次导出 JSONL。

每个事件至少记录：

```text
action / actionMasked / actionIndex / actionButton / buttonState
source / deviceId / vendorId / productId
pointerId / toolType
eventTime / downTime
x / y / pressure / tilt / orientation / distance
historySize 以及全部 historical samples
flags / canceled 状态
当前屏幕 refresh rate
```

Android 的 `ACTION_MOVE` 可包含多个历史采样。只读取当前坐标会主动丢弃系统已经批量交付的点，因此探针和后续原生桥必须遍历 `historySize`。

探针动作矩阵：

1. 悬停；
2. 普通落笔；
3. 从轻压到重压；
4. 快速直线与曲线；
5. 慢速直线；
6. 不同倾斜角；
7. 悬停时侧键按下/松开；
8. 落笔时侧键按下/松开；
9. 双击；
10. 手掌先接触后落笔；
11. 笔先落下后放手掌；
12. 双指缩放期间笔悬停。

输出 `oppo-pencil2-capabilities.json`。侧键只有在普通应用层观察到明确 down/up 语义时，才能承诺“按住临时橡皮擦”；若只有双击，则需求标记为硬件限制。

## E6. 性能观测工具与 Trace 命名

工具按层使用：

1. **Flutter DevTools**：UI/Raster frame、widget rebuild、GC；
2. **Android Studio Profiler / System Trace / Perfetto**：线程调度、frame timeline、I/O、CPU、RSS；
3. **Simpleperf**：Rust/SQLite/native `.so` 的函数和调用图；
4. **应用内统计**：Command、bake、raycast、FFI、DB commit 的 P50/P95/P99。

统一 Trace section：

```text
stylus.dispatch
stylus.history.decode
stroke.foreground.update
stroke.commit
backend.apply_command
rust.apply_command
sqlite.begin
sqlite.commit
viewport.query
viewport.bake
selection.raycast
eraser.split
history.undo
history.redo
```

所有 trace 名必须稳定，禁止在每次重构中随意重命名，否则历史基准无法比较。

## E7. Root 策略

### E7.1 正式结论

> V1 必须能在无 Root 条件下完整开发、运行和保存数据。Root 仅是只读诊断分支，不进入日常运行路径。

无 Root 已能完成：

- USB/Wi-Fi ADB；
- Flutter hot reload；
- Logcat、断点和 profileable profiling；
- Perfetto/System Trace；
- Simpleperf 分析自己的应用；
- `run-as`/Device Explorer 访问自己的 debug 数据；
- SQLite 导出、故障测试和恢复。

### E7.2 何时允许进入 Root 诊断

仅当以下问题在标准 API 下无法解释时进入 Root 分支：

1. OPPO Pencil 2 侧键完全未出现在 MotionEvent/KeyEvent/GenericMotionEvent；
2. 输入事件存在不可解释丢失，需要确认 Linux input 层是否收到；
3. 厂商输入服务或驱动行为需要只读观察；
4. 普通 profileable 工具无法解释内核级调度或设备节点。

Root 阶段首先只运行只读命令，例如：

```text
su -c 'cat /proc/bus/input/devices'
su -c 'getevent -lp'
su -c 'getevent -lt /dev/input/eventX'
```

禁止为了调研直接修改 SELinux、刷入模块、替换驱动或让日用应用依赖 root daemon。Root 能看到原始事件，不等于普通应用能获取该事件；这两种结论必须分别记录。

### E7.3 基线顺序

Root 前必须先保存：

- 原厂系统 build fingerprint；
- Butterfly 原版与 fork 的 Profile/Release 基准；
- 三组代表性 Perfetto trace；
- 输入能力报告；
- boot 镜像和恢复方案（若用户随后自行 Root）。

Root 后的测量不得与原厂数据混在同一组。

## E8. 日常开发闭环

```text
普通 UI / 逻辑
→ AVD Debug + 自动测试

输入 / 手势
→ OPPO 真机 Debug + 输入探针

性能变化
→ OPPO 真机 Profile
→ 关闭镜像/录屏
→ DevTools + Perfetto

Rust / SQLite
→ PC 单元与属性测试
→ AVD migration / fault tests
→ OPPO 真机 I/O 与帧时间联合基准

准备日用
→ personalRelease
→ 连续真实书写
→ 备份与恢复演练
```

任何优化结论都必须附带 run record；没有 profile/release 真机数据的“更流畅”只能记为主观观察。

## E9. 推荐的第一个七日执行周期

1. **工具链**：安装 Android Studio、API 36、Platform Tools、Flutter 3.44.1、Rust、NDK，运行 preflight。
2. **原版构建**：原样编译 `v2.5.3`，分别运行 AVD 与 OPPO 真机。
3. **构建变体**：打通 `devDebug`、`devProfile`、`personalRelease`，分离 applicationId。
4. **输入探针**：完成 MotionEvent ring buffer 与能力矩阵。
5. **M2 定向基线**：在空文档和一个代表性压力文档上重放固定的写、擦、套索、undo 序列；完整规模曲线留到对应性能决策门。
6. **自动测试**：在 AVD 跑保存重开、迁移、故障恢复、undo/redo。
7. **第一次门控**：根据证据决定 M2 的优先拆分点，不允许在基线缺失时直接引入 Jetpack Ink 或替换 Baking。

---
# 第四部分：渐进式重构路线

## 11. 阶段总览

| 阶段 | 权威状态 | 用户可见变化 | 退出门槛 |
|---|---|---|---|
| M0 基线冻结 | Butterfly 2.5.3 | 无 | tag、需求 hash、基准 APK、测试文档齐全 |
| M1 可观测性与输入探针 | Butterfly | 仅调试页 | 输入事实已建立，且 M2 将改动的写操作可被行为 oracle 与定向 trace 比较 |
| M2 后端接口抽离 | Legacy Dart | 行为不变 | UI/Handler 不再直接操作 DocumentBloc 元素集合 |
| M3 Rust 影子后端 | Legacy Dart | 行为不变 | M2 replay 逐命令 100% 一致，零未解释差异 |
| M4 Rust 权威最小原型 | Rust（仅已切换命令） | 无限画布、单笔、写/整笔擦、撤销 | 最小命令子集 parity、单 writer、事务恢复和冻结性能门槛通过 |
| M5 编辑能力 | Rust | 局部擦、套索、移动 | 每项独立语义/事务门通过，操作后无持续退化 |
| M6 分页与直接恢复 | Rust | V1 完整范围 | 文档模式、session、UI 三个 owner 分别验收 |
| M7 活动墨迹决策门 | Rust | 可能无变化 | 仅在 active path 触发条件成立时做同路径对照 |
| M8 稳定渲染决策门 | Rust | 可能升级缓存 | 仅在 stable renderer owner 被证明是瓶颈时做 tile 对照 |

### 11.1 M0：不可变基线

执行：

1. Fork Butterfly。
2. 创建 `baseline/v2.5.3-pristine`，指向官方 `v2.5.3`，永久不提交修改。
3. 创建 `baseline/v2.5.3-instrumented`。
4. 保存官方 APK、自己的 release/profile APK、Gradle lock、Flutter 3.44.1、Dart 和 NDK 版本。
5. 建立固定测试文档和操作脚本。
6. 把本计划、需求 JSON 与 source ledger 提交进 `docs/project-baseline/`。

禁止：直接在 moving main 上开发；第一步就替换存储；第一步就引入 Jetpack Ink。

### 11.2 M1：可观测性与设备探针

新增调试模块：

```text
app/lib/debug/performance/
android/app/src/main/kotlin/.../StylusProbePlugin.kt
```

记录：

- Flutter `PointerEvent` 的时间戳、kind、pressure、tilt、buttons；
- 原生 MotionEvent 的 eventTime、historySize、每个历史点的 x/y/pressure/tilt/orientation；
- deviceId、vendorId、productId、toolType、source；
- buttonState、actionButton、KeyEvent、GenericMotionEvent；
- 当前屏幕刷新率；
- 每帧 Flutter build/raster/total；
- bake、raycast、save、FFI、DB transaction 的 trace section。

输出为 JSONL，而不是在每个事件上写日志到 Logcat。使用内存 ring buffer，测试结束后一次导出。

#### 11.2.1 M1 到 M2 的最小充分门

门槛从下游决策反推，不要求在 M2 前完成所有产品性能验收。

M2 的 Commit 1（DTO/接口）和 Commit 2（尚未接管调用方的 Legacy adapter）
是加法变更，可以在输入探针验证后立即开始。第一个 Handler 切换所有权前必须冻结：

1. Legacy 写操作行为 oracle：CreateStroke、EraseStrokes、PartialErase、
   TranslateSelection、Undo、Redo、取消中的笔迹和保存重开；
2. 每一步的规范化文档状态、history cursor 与 created/updated/removed 集合；
3. 可重复 owner-boundary replay，而不是依赖操作者手速；
4. 当前 instrumented pre-M2 `devProfile` 基线：空文档和一个代表性压力文档，
   固定序列至少重复三轮；
5. 在看到 post-M2 数据前冻结行为一致和性能回归判定规则。

以下项目不阻塞 M2：Notein 三方对比、纯 60 Hz 双指场景、12 项 Pencil
动作各自独立 trace、Wi-Fi ADB、personalRelease 体验、240/480 fps 光学录像和
六类红线的完整规模曲线。它们分别属于快捷键/掌托功能门、M4 以后发布门或
M7/M8 技术选型门。若 M2 实际修改了对应责任边界，再把相关项目提升为门槛。

### 11.3 M2：抽离 Legacy 后端，不改行为

目标是让现有代码先满足：

```text
Handler -> Command -> DocumentBackend -> Delta -> Renderer sync
```

而不是：

```text
Handler -> DocumentBloc.add(ElementsChanged/Removed/Created) -> 多处副作用
```

具体拆法：

1. 建立 `CommandDto`：CreateStroke、RemoveElements、ReplaceElements、TranslateElements、Undo、Redo。
2. 建立 `DocumentDelta`：created、updated、removed、dirtyBounds、revision。
3. 用 `LegacyDartBackend` 包装现有 Bloc event。
4. 选择状态从 `List<Renderer>` 改为 `Set<ElementId>`；Renderer 只在 ViewModel 中按 ID 查找。
5. raycast/lasso 接口返回 ID，不返回 Renderer。
6. 让前景预览仍使用旧 Renderer，但提交只通过 Backend。
7. 所有行为均以 v2.5.3 为 oracle，先不“顺便修正”。

DTO/接口和未接管调用方的 adapter 可以先行；第一个 Handler 切换前必须满足
11.2.1 的 oracle、replay、两档 fixture 三轮基线与预冻结裁决规则。M2 验收只比较
自己改变的 Handler → Backend → Delta 责任链，不以完整产品性能矩阵替代行为等价证据。

### 11.4 M3：Rust 影子执行

每个命令同时发送给：

- LegacyDartBackend；
- RustShadowBackend。

Legacy 的结果继续驱动 UI；Rust 只计算并生成 canonical state。比较：

- 元素种类、ID、空间、z-order；
- 点序列、压力、属性；
- bounds；
- 当前 revision；
- undo/redo 后状态。

随机 ID 通过注入 `IdGenerator` 固定；若旧代码无法固定，则规范化比较时建立 ID 映射，不允许简单忽略 ID 关系。

不一致时输出最小 diff：

```text
command #184: ReplaceElements
legacy: removed A, created B/C
rust:   removed A, created B
first mismatch: C.points[17].x
```

M3 开始前固定 canonical state、ID/浮点/顺序规范化和允许忽略的纯缓存字段；
不得在看到 diff 后扩大 ignore list 来制造一致。退出条件是 M2 固定 replay 和
版本化属性序列对所有已实现命令零未解释差异。Shadow 队列、文件和开销必须有界，
但数据库耐久性、活动墨迹和稳定渲染不属于本阶段责任。

### 11.5 M4：Rust 权威最小原型

切换最小垂直链：

- 无限画布；
- 单一压力笔；
- 手指导航；
- 整笔画橡皮擦；
- stroke-level undo；
- SQLite；
- 重启恢复。

此时仍保留 Butterfly 的 UI 与 stable renderer。所有旧功能可以继续只读显示，但只有迁移完成的 V1 命令允许写入 Rust 文档。

Rust 只接管已经通过 Shadow parity 的最小命令子集。切换前冻结 schema、
transaction/revision、恢复与 durability 语义，并通过新建、正常关闭、force-stop、
事务/迁移中断、备份恢复和目标真机 SQLite profile。未迁移写功能关闭而不是双写；
feature flag 回退也不得让 Legacy 与 Rust 同时写同一文件。

### 11.6 M5-M6：编辑与分页

按以下顺序接管：

1. 局部橡皮擦；
2. 自由套索；
3. 选区移动；
4. 分页文档；
5. 启动直接恢复；
6. 最小工具栏整理。

顺序理由：分页依赖稳定的 Space/Element/Command/DB；不应先在旧 Bloc 上再实现一次。

M5 的局部擦除、套索和移动分别冻结输入合同、语义来源、真实病例、不变量、
单手势事务/历史/Delta 以及编辑后回归规则，并逐项切换。若有意修复 Legacy，
先写 ADR，把行为变更与所有权迁移分开。

M6 分别验收三个 owner：Paged/Infinite 文档模型、session 恢复、工具栏与临时工具状态。
Notein 只作交互参考，不是未经验证的行为或性能 oracle；personalRelease 长时间使用是
产品体验证据，不能替代恢复、事务和虚拟化的 owner-boundary 测试。

### 11.7 后续阶段的统一门槛原则

每次权威切换只要求能证明本次改变的责任链：

1. 输入合同与当前 owner 已明确；
2. 原行为或新需求的 oracle 已冻结；
3. 同一确定性 replay 可在切换前后运行；
4. 裁决规则在结果出现前冻结；
5. 失败可观察且回退不会形成双 writer/双真相；
6. 产品发布、光学延迟、完整容量曲线等只在对应 owner 或决策门被触发时升级为阻塞项。

---

# 第五部分：每项功能的详细参考实现

## 12. 功能 0：OPPO Pencil 2 输入能力探针

### 12.1 目的

在写任何侧键兼容代码前，确定设备真实提供什么。公开产品页不能代替 MotionEvent 实测。

### 12.2 原生采集字段

```kotlin
StylusSample(
    actionMasked,
    actionButton,
    buttonState,
    toolType,
    source,
    deviceId,
    eventTimeNanos,
    x, y, pressure,
    tilt, orientation, distance,
    history: List<HistoricalSample>
)
```

同时采集：

- `MotionEvent.BUTTON_STYLUS_PRIMARY`；
- `MotionEvent.BUTTON_STYLUS_SECONDARY`；
- `KeyEvent`；
- `onGenericMotionEvent`；
- 笔身双击前后系统是否发送 broadcast/shortcut action；
- 快捷按键是否被 ColorOS 完全消费。

### 12.3 测试动作

1. 正常慢写、快速横线、快速小字。
2. 轻压到重压。
3. 悬停。
4. 笔身双击、快捷键单击、长按、按住书写、松开。
5. 同时放下手掌。
6. 60 Hz 与 120 Hz 模式分别记录。

### 12.4 验收

输出一份 `DEVICE_CAPABILITIES_OPPO_PAD4PRO.json`，明确：

- 原生样本频率分布；
- Flutter 收到的事件数量与原生历史样本数量之比；
- 压力有效范围；
- 倾角/方向是否变化；
- 快捷动作的真实事件语义。

没有该文件，不得开始“侧键临时橡皮擦”实现。

---

## 13. 功能 1：单一压力钢笔

### 13.1 当前 Butterfly 参考

- `PenHandler` 在前景层维护活动 `PenElement`；
- 每个 PointerMove 添加一个 `PathPoint`；
- 抬笔后发送 `ElementsCreated` 并延迟 bake；
- `PenRenderer` 使用 `perfect_freehand` 根据 size、thinning、smoothing、streamline 与 pressure 生成轮廓。

这套 wet/dry 分层值得保留，但输入事实与渲染缓存需要分开。

### 13.2 目标事件流

```text
Stylus down
  -> Frontend StrokeDraft.begin()
Stylus move
  -> consume all available samples
  -> append raw points
  -> causal live model
  -> foreground repaint only
Stylus up
  -> append final/history samples
  -> finalize draft
  -> backend.apply(CreateStroke(rawPoints, brush))
  -> SQLite transaction + R-tree insert
  -> DocumentDelta(created, dirtyBounds)
  -> stable renderer receives committed element
  -> foreground removes wet stroke only after dry stroke可见
```

### 13.3 防丢样本

原生 MotionEvent 的一次 ACTION_MOVE 可以含多个历史样本；Butterfly 当前 Flutter 路径只按 PointerMoveEvent 添加一个点。第一阶段必须量化 Flutter 是否已经展开了历史点。若未展开：

- 短期：Android plugin 批量传入 `StrokeInputBatch`；
- 长期：Jetpack Ink/native overlay 接管活动墨迹；
- 禁止用“插值更多点”冒充真实采样保存。

### 13.4 原始点去重

只做明确的输入去重：

```text
相同 timestamp + 相同坐标 -> 去重
明显非法 NaN/Inf -> 在输入边界拒绝整次样本
```

不要在活动阶段按距离大规模抽稀。点简化属于可重建的渲染缓存，不应破坏 raw_points。

### 13.5 FFI

抬笔后一次传递：

```rust
CreateStroke { space_id, brush, raw_points: Vec<RawStrokePoint> }
```

使用 `flutter_rust_bridge` stable 2.12.0；`DocumentSession` 使用 opaque handle。大点数组采用 typed data/zero-copy 能力，但是否真正零拷贝以 benchmark 结果为准，不能从 API 宣传推断。

### 13.6 验收

- 空白、1k、10k、50k 历史笔画下，活动笔画前景耗时不出现与 N 成比例的增长；
- 原生样本与存储 raw points 数量差异只能来自已记录的重复样本规则；
- pen-up 到 stable stroke 接管无闪烁、无重复笔迹；
- 强制杀进程后，已提交的完整笔画存在，未完成笔画可丢弃。

---

## 14. 功能 2：可调笔迹平滑/稳定

### 14.1 两层模型

```text
raw points      = 永久事实
modeled points  = 由 smoothing profile 计算
outline/mesh    = 由 modeled points + brush 计算
```

### 14.2 迁移阶段

**阶段 A：行为等价**  
Rust 保存原始点，Flutter 继续使用 Butterfly/perfect_freehand 的 smoothing 与 streamline，保证视觉不变。

**阶段 B：统一算法**  
将平滑配置抽象为：

```rust
SmoothingProfile {
    stabilization: f32,   // 0..1
    streamline: f32,      // 0..1
    pressure_smoothing: f32,
}
```

活动阶段使用因果滤波，不能依赖很长的未来窗口。完成后可以进行一次确定性的全笔画建模，但必须满足“抬笔前后不明显跳变”。

### 14.3 推荐原则

- live path 最多允许极短固定延迟；
- final path 与 live path 使用相同核心模型；
- 所有算法输入包含时间间隔，不能假设样本均匀；
- 平滑强度变化不修改 raw points；
- 同一 raw stroke + profile 必须生成确定性结果。

### 14.4 测试

固定输入 fixture：

- 慢直线；
- 快速折线；
- 小圆；
- 中文横竖撇捺；
- 高频抖动；
- 不均匀采样。

输出 modeled points、bounds、SVG golden 和最大偏移。调参不得靠主观感觉而不保存回归样例。

---

## 15. 功能 3：手写笔书写，手指导航

### 15.1 指针路由状态机

```text
Stylus tip / eraser tool type -> active tool handler
Finger, one pointer           -> pan
Finger, two pointers          -> pan + pinch zoom
Palm / canceled pointer       -> reject/cancel according to explicit classifier
```

V1 默认采用：**单指平移、双指缩放**。这参考 Notein 的高频交互思路，但不复制其全部手势层。

### 15.2 不变量

- Finger 事件永远不创建 Stroke；
- Stylus down 后，新增 finger/palm 不能夺走活动笔画；
- `ACTION_CANCEL` 必须取消 wet stroke，不提交半条命令；
- 相机变化不清空 temporary tool；
- 手势结束不触发全量 bake，只更新 viewport query 和必要缓存。

### 15.3 相机状态

```rust
CameraState {
    space_id: SpaceId,
    center_x: f64,
    center_y: f64,
    zoom: f64,
}
```

相机仍由 Flutter 实时维护，不需每帧写 Rust/DB。仅在手势结束或节流后发送 viewport query；关闭/后台时保存最终相机状态。

### 15.4 异步 viewport query

每次 query 带 generation：

```text
query #41 sent
query #42 sent
#42 returns -> accept
#41 returns -> discard as stale
```

避免快速平移时旧结果覆盖新视口。

---

## 16. 功能 4：OPPO Pencil 2 快捷动作与临时橡皮擦

### 16.1 工具状态模型

```rust
ToolState {
    persistent: ToolId,
    temporary_stack: Vec<TemporaryTool>,
}
```

按下/松开语义存在时：

```text
BUTTON_DOWN -> push Temporary(StrokeEraser, source=StylusButton)
BUTTON_UP   -> pop source=StylusButton, restore persistent tool
```

双击单次动作时：

```text
DOUBLE_TAP -> ToggleLastTool 或 ToggleEraser
```

两者不能混为一谈。

### 16.2 设备约束处理

- 若 Pencil 2 暴露 Android stylus button bit：实现真正按住临时擦除；
- 若只暴露厂商双击：V1 实现明确标注的“双击切换”，同时在需求差异记录中标记原“临时切换”未满足；
- 若系统消费全部动作：不写大量设备猜测 fallback；保留工具栏入口并记录阻塞。

### 16.3 测试

- 写到一半按键、按住擦除、松开继续写；
- 按键时触发平移；
- 快速重复按键；
- 应用失焦时按钮仍按住；
- `ACTION_CANCEL` 后 temporary stack 必须清理。

---

## 17. 功能 5：整笔画橡皮擦

### 17.1 复用 Butterfly 的正确交互模式

Butterfly 当前 PathEraser 已采用：

- 移动时 raycast；
- 把命中的 ID 加入 `_erased`；
- 主层临时隐藏；
- 抬笔后一次提交 `ElementsRemoved`；
- 然后重新 bake。

目标后端保留这种“预览与提交分离”，但 raycast 和文档更新转移到 Rust。

### 17.2 Rust 流程

```text
Eraser gesture start
  -> EphemeralEraseSession
Move sample
  -> query R-tree with eraser AABB
  -> narrow-phase distance/outline hit
  -> add ElementId to hidden set
  -> frontend delta only updates ephemeral hidden IDs
Pointer up
  -> RemoveElements(ids) as one command
  -> SQLite transaction
  -> remove/reinsert index entries
  -> return dirty bounds union
```

### 17.3 复杂度

- Broad phase：`O(log N + K)`；
- Narrow phase：只处理候选 K；
- 同一笔画同一手势只命中一次；
- 不在每个 move 写数据库；
- 不在每个 move 重建整份可见 renderer 列表。

### 17.4 验收

- 50k 笔画文档中，橡皮只与附近候选相关；
- 抬笔提交后没有全局持续卡顿；
- 一次橡皮手势一次 undo；
- 隐藏预览与最终删除一致。

---

## 18. 功能 6：局部像素式橡皮擦

### 18.1 当前实现的不足

Butterfly 2.5.3 `_cutPenElement` 逐点检查：点在橡皮圆内就删除，并在空隙处切段。问题：

- 两个采样点都在圆外，但连接线穿过圆时可能漏擦；
- 切口只落在原始采样点，位置粗糙；
- 没有考虑局部笔宽；
- 多次擦除会产生大量小碎片；
- 新 fragment ID 与 undo/选择语义需要原子管理。

### 18.2 V1 几何语义

采用**中心线 + 局部笔宽修正的连续切割**，不追求第一版 mesh 精确布尔运算。

橡皮轨迹由一系列 swept capsules 构成：

```text
capsule(segment_i, radius = eraser_radius)
```

对每条候选笔画的每个中心线段：

1. 计算线段与 capsule 的进入/离开参数区间；
2. 以精确交点插入新样本；
3. 对 pressure、elapsed、tilt、orientation 线性插值；
4. 删除落入擦除区间的部分；
5. 生成有序 fragments；
6. 丢弃长度和面积低于明确阈值的碎片；
7. 使用一条 `ReplaceElements { old_id -> new_fragments }` 原子命令提交。

命中半径可采用：

```text
effective_radius = eraser_radius + local_stroke_half_width
```

### 18.3 性能策略

- 先用 eraser swept-path 的总 AABB 查询 R-tree；
- 每个候选 stroke 只在抬笔或小批次时切割；
- 移动中可先显示 mask/临时 fragment，不每个样本提交永久结果；
- 同一原始 stroke 在一个手势中只进行一次最终重建；
- fragment 过多时输出明确性能诊断，不静默退化成整笔删除。

### 18.4 为什么不直接用 Jetpack Ink 1.1 partial eraser

截至 1.1.0-alpha05，该能力仍是 experimental，官方明确说明切口缺抗锯齿且擦除后的 `PartitionedMesh` 没有序列化 API。它可用于实验对照，不可成为 V1 可持久化语义。

### 18.5 测试矩阵

- 稀疏点长直线中间擦除；
- 高压力粗笔；
- 多次穿越同一 stroke；
- 擦除端点；
- 擦除闭合曲线；
- 极短 fragment；
- undo 后严格恢复原始 raw points 与 ID 关系。

---

## 19. 功能 7：自由套索

### 19.1 迁移原则

现有 SelectHandler 直接保存 Renderer 列表，并在结束时调用 `rayCastPolygon`。第一步不是重写算法，而是把：

```text
selected Renderers
```

替换为：

```text
SelectionState { ids: OrderedSet<ElementId> }
```

### 19.2 套索采样

- 套索是 UI 临时轨迹，不写数据库；
- 以屏幕像素阈值采样，避免缩放改变手感；
- 结束后转换为世界坐标；
- 使用 Ramer–Douglas–Peucker 或等效算法简化，但保留闭合性；
- 自交套索的语义必须固定。V1 优先采用 even-odd fill rule。

### 19.3 命中流程

```text
lasso AABB -> R-tree broad phase
candidate bounds -> polygon AABB quick reject
stroke centerline/outline -> polygon narrow phase
```

### 19.4 选择语义

为保证“先保留行为”，M2-M3 先建立 Butterfly 2.5.3 oracle fixtures：

- 完全在套索内；
- 仅一个端点在内；
- 线段穿过但所有采样点在外；
- bounds 相交但真实线不相交；
- 套索自交。

Rust 必须复制被测试确认的旧语义。若后续决定改为“只要相交即选择”或“必须完全包含”，这是产品需求变更，不能作为重构顺手修改。

### 19.5 验收

- 10k 候选外元素不进入窄相测试；
- 选择结果确定性；
- 套索结束后不触发持续 bake 退化；
- 选择状态不持有 Renderer 引用。

---

## 20. 功能 8：选区移动

### 20.1 交互与提交分离

拖动期间：

- Flutter 用临时 transform 绘制选中元素；
- stable layer 隐藏原元素；
- Rust 文档不随每个 pointer move 改动。

抬手时：

```rust
TranslateElements { ids, dx, dy }
```

形成一个事务。

### 20.2 数据表示

现有 Butterfly PenRenderer 会重写每个点坐标。目标模型优先采用 element transform/offset：

- 移动大量笔画时只更新 header transform/bounds；
- raw point blob 不重写；
- R-tree 中 remove + reinsert 新 bounds；
- 导出旧 Butterfly 格式时，compat 层再把 transform bake 到点坐标。

M2 行为等价阶段仍可使用旧重写方式；Rust 权威后切换为 transform 是一次独立、可验证的数据迁移。

### 20.3 验收

- 移动 500 条笔画时，拖动帧不调用 DB；
- 抬手只有一个 transaction；
- undo 恢复旧 transform 与 bounds；
- 大选区移动成本不与所有点总数线性绑定，除非导出兼容格式。

---

## 21. 功能 9：撤销/重做

### 21.1 命令粒度

| 用户动作 | 历史单位 |
|---|---|
| 一次完整落笔 | CreateStroke 1 条 |
| 一次整笔橡皮手势 | RemoveElements 1 条 |
| 一次局部擦除手势 | ReplaceElements 1 条 |
| 一次选区拖动 | TranslateElements 1 条 |

### 21.2 Rust history 模型

```rust
pub struct HistoryEntry {
    pub seq: i64,
    pub command: Command,
    pub inverse: Command,
    pub before_revision: u64,
    pub after_revision: u64,
}
```

数据库中 command、文档修改和 cursor 更新必须在同一个 SQLite transaction 中提交。

### 21.3 redo 分支

- undo 后执行新命令：删除 cursor 之后的 redo entries；
- V1 使用线性历史，不做分支历史树；
- 历史上限通过可配置 cap 和 checkpoint 控制；
- 不把 ReplayBloc 的整个状态快照继续作为长期 undo 后端。

### 21.4 验收

- 1000 次连续笔画后 undo/redo 不复制整份文档；
- partial eraser undo 恢复原始 stroke，而不是重新拼接近似版本；
- 崩溃恢复后历史 cursor 与文档 revision 一致；
- DB commit 失败时文档与 history 不允许一半成功。

---

## 22. 功能 10：无限画布

### 22.1 目标模型

- 一个 `InfiniteCanvas` Space；
- 世界坐标 f64；
- 相机 f64；
- 元素按 AABB 进入内存 R-tree；
- viewport query 只返回可见区域加 prefetch margin。

### 22.2 打开策略

V1 可在打开时一次加载所有 element headers/bounds 和必要元数据，raw point blobs 按需加载。只有 benchmark 证明 headers 也过大，才增加数据库 R*Tree 冷查询。

原因：

- 内存 `rstar` 支持 f64 并方便修改；
- SQLite R*Tree 默认使用 f32，虽然重叠查询向外舍入不会漏候选，但巨大无限坐标下精度需要额外审查；
- 单设备个人笔记的 200k element headers 通常比复杂的双重索引一致性更可控，但必须以测量为准。

### 22.3 预取

```text
queryBounds = viewportBounds.expand(screenSizeInWorld * 0.5)
```

平移时优先复用上一 snapshot；后台加载新的可见元素。不能在每个手势帧同步访问 SQLite。

### 22.4 验收

- 50k/200k 笔画 fixture 下平移只处理可见与预取候选；
- 冷打开时间、首次可写时间分开记录；
- 即使后台还在加载远处内容，也必须允许在当前区域写字。

---

## 23. 功能 11：分页文档

### 23.1 建立在无限原型之后

分页不是独立第二套内核，只增加：

- `DocumentMode::Paged`；
- 多个 Page Space；
- 固定页面 bounds；
- 页面排列与虚拟化；
- 当前 page/scroll position 恢复。

### 23.2 V1 交互决策

采用成熟产品常见的：

- 纵向连续页面；
- 单指滚动；
- 双指缩放；
- 页面之间固定 gap；
- 元素不能跨页；
- 页面局部坐标，避免随页序变化重写元素坐标。

这是一项本文的实现决策，而非用户原始明确答案；若后续希望横向翻页或跨页书写，需新增需求决策。

### 23.3 虚拟化

- 只为可见页面创建 View/Renderer；
- 相邻页面预取；
- 每页独立 stable cache；
- reorder page 只改 page order，不改元素数据；
- DB transaction 中更新 page index/order。

### 23.4 验收

- 100 页文档只维持少量可见页面渲染资源；
- 页面重排不重写 stroke blobs；
- 分页与无限文档共享笔、擦、套索、移动和 undo 命令实现。

---

## 24. 功能 12：启动直接恢复

### 24.1 app-level 数据库

单独的小型 `library.db` 保存：

```text
last_document_id
last_space_id / page_id
camera center + zoom
persistent tool id
last clean shutdown marker
```

文档内容存于各自 document DB，避免一个文档损坏拖累全部文档。

### 24.2 启动流程

```text
start
 -> read library.db
 -> resolve last document
 -> open metadata + current space
 -> show first usable viewport
 -> background load noncritical data
```

若恢复失败：显示明确错误与文档列表；不能静默新建空白文档，让用户误以为数据丢失。

### 24.3 验收

- 正常退出、系统杀进程、强制停止后均恢复到最后一次已提交命令；
- 未完成 wet stroke 不恢复；
- 首屏可写时间独立于整个文档所有 raw blobs 的加载。

---

## 25. 功能 13：最小工具栏与 Notein 思路参考

### 25.1 参考而不复制

Notein 的值得参考点：

- 可快速切换的笔盒/工具栏；
- 橡皮擦具有整笔和像素模式；
- 自由套索；
- 手写笔快捷动作；
- 沉浸式与固定工具栏思路；
- 双指导航和高频 undo 手势。

V1 不复制其功能密度。

### 25.2 V1 工具栏

固定顶部或边缘的紧凑栏，只有：

```text
Pen | Stroke Eraser | Partial Eraser | Lasso | Undo | Redo
```

Pen 二次点击或长按打开：

```text
颜色 | 宽度 | smoothing
```

原则：

- 工具切换一次触达；
- 不用多层菜单寻找整笔/局部擦除；
- 持久工具与临时工具视觉状态明确；
- 工具栏动画不能触发画布 rebuild；
- Toolbar 通过 `ToolRegistry` 注册，不在 UI 中维护巨大 switch。

### 25.3 Registry

```dart
abstract interface class ToolProvider {
  ToolId get id;
  Widget buildToolbarItem(ToolContext context);
  ToolHandler createHandler(ToolContext context);
}

abstract interface class CommandProvider {
  CommandType get type;
  Future<DocumentDelta> execute(CommandContext context, CommandDto command);
}
```

Registry 只是编译期内部扩展点，不做动态插件发现、安全沙箱或版本解析。

---

# 第六部分：SQLite 数据库与事务

## 26. 存储决策记录

### 26.1 最终决策

V1 与当前长期路线继续使用 **SQLite**，不替换为 redb、LMDB、RocksDB 或自制日志数据库。

这项决策不是因为 SQL 天然适合笔迹，而是因为当前负载满足 SQLite 的优势边界：

- 单设备本地数据；
- 每份文档一个文件；
- 一个 Rust `DocumentSession` 串行拥有所有写事务；
- 数据规模远小于 SQLite 上限；
- 需要成熟的崩溃恢复、备份、完整性检查与诊断工具；
- 数据不可轻易重新生成，可靠性优先级高于纯微基准吞吐量。

SQLite **不进入实时墨迹路径**。实时书写读取 Rust 内存文档、空间索引和前端活动笔画；SQLite 只在一个完整命令或手势结束后持久化事务。因此，换数据库不能解决笔尖延迟，正确的目标是限制数据库提交和维护对渲染尾延迟的干扰。

### 26.2 与 1.0.0 计划的差异

以下旧假设被撤销：

```text
SQLite 必然采用 WAL
WAL + NORMAL 是默认答案
所有 connection 使用 busy_timeout 兜底
BLOB UUID 直接作为大型 elements 表 PRIMARY KEY
```

更新后的结论是：

1. **SQLite 引擎固定，但 journal mode 不预设。** `WAL + FULL`、`WAL + NORMAL` 与 rollback-journal 方案必须在 OPPO Pad 4 Pro 上以相同耐久语义比较。
2. **WAL 的价值需要证据。** 当前架构只有一个 writer，前端也不直接读数据库；若不存在并发数据库读，WAL 的核心并发优势会减弱。
3. **提交成功的耐久语义必须明确。** `WAL + NORMAL` 可承受应用进程崩溃，但系统崩溃或断电后最近已返回成功的事务可能回滚；`WAL + FULL` 才要求每次提交额外同步 WAL。
4. **大型 payload 表使用普通 rowid 表。** `WITHOUT ROWID` 主要适合非整数/复合主键且行较小的表，不适合作为包含较大 Stroke BLOB 的默认选择。
5. **备份必须通过 SQLite API 完成。** 活跃 WAL 数据库不能只复制主 `.notedb` 文件。

### 26.3 Rust 依赖与版本固定

Rust 侧使用 `rusqlite` 的 bundled SQLite，而不是 Android 系统 SQLite：

```toml
[dependencies]
rusqlite = { version = "0.40.1", features = ["bundled", "backup"] }
```

执行要求：

- 实际版本由 `Cargo.lock` 固定；
- 每次升级 `rusqlite/libsqlite3-sys` 时记录 `sqlite_version()` 与 `sqlite_source_id()`；
- bundled 构建保证开发、测试和目标设备使用同一 SQLite 功能集；
- 不依赖设备厂商预装 SQLite 是否过旧或编译选项是否不同；
- schema 迁移和故障测试必须在升级后完整重跑。

当前调研时 `rusqlite 0.40.1` 的 bundled 模式包含 SQLite 3.53.2；实施时不得把该版本号写成永久前提，应以锁文件和运行时诊断为准。

## 27. 数据库拓扑与连接所有权

### 27.1 文件布局

```text
app data/
├── library.db
├── documents/
│   ├── <document-id>.notedb
│   └── ...
└── backups/
    ├── <document-id>-<revision>-<timestamp>.notedb
    └── ...
```

若最终选择 WAL，运行时还会出现：

```text
<document-id>.notedb-wal
<document-id>.notedb-shm
```

这两个文件是 SQLite 的运行时组成部分，不是可忽略的缓存。不得在数据库打开时只复制 `.notedb` 主文件并把它当作完整备份。

每份文档一个数据库：

- 故障与损坏隔离；
- 文档导出、备份和替换边界清晰；
- 一个打开文档对应一个 writer actor；
- 不让统一大库承担跨文档锁、迁移和 vacuum 风险；
- 删除或归档文档只操作其独立数据库与备份记录。

### 27.2 单写者纪律

一个 `DocumentSession` actor 独占：

- SQLite writer connection；
- 权威 `Document`；
- 内存 R-tree；
- history cursor；
- document revision；
- checkpoint、backup 与 maintenance 调度权。

禁止：

- Flutter UI 直接打开数据库；
- 工具处理器各自持有 SQLite connection；
- 每个后台任务自行写入；
- 用长 `busy_timeout` 隐藏内部连接竞争；
- 在 pointer move、hover、viewport frame 中执行 SQL。

正常命令提交出现 `SQLITE_BUSY` 应视为架构错误并记录诊断，而不是无限等待。只有 Online Backup 等明确的第二连接操作可以使用短且有上限的 busy handler，并且必须在 actor 边界协调。

### 27.3 内存与数据库的关系

数据库是持久化真相，打开后的 Rust `DocumentSession` 是运行期权威状态：

```text
Open
  -> SQLite 读取 header / payload
  -> 构建 Rust Document + R-tree
  -> 正常编辑只查询内存

Gesture commit
  -> 在内存 snapshot 上验证 Command
  -> SQLite transaction 持久化 element/history/revision
  -> COMMIT 成功
  -> 发布 DocumentDelta
```

若事务失败，不得把已经只存在于内存的变化发布给前端。活动笔画可在前端临时显示，但完成笔画只有在后端事务成功后才成为稳定文档事实。

## 28. Schema v1.1

### 28.1 设计原则

1. 逻辑 ID 与 SQLite 物理 rowid 分离。
2. 大型 Stroke payload 保持“一条元素一个 BLOB”，不把每个采样点拆成 SQL 行。
3. 只将启动、筛选和空间索引需要的 header 字段列式保存。
4. header、payload、history 和 revision 必须在同一事务中更新。
5. 使用 `STRICT` tables 限制数据库边界的类型错误。
6. `PRAGMA user_version` 表示 SQLite schema 迁移版本；payload 语义版本另存，不混用。
7. elements/history 不使用 `WITHOUT ROWID`：它们已有整数主键且包含大型 BLOB；保留普通 rowid 也为将来的 incremental BLOB I/O 和 R*Tree 外键留出空间。

### 28.2 建议 DDL

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE meta (
  key   TEXT PRIMARY KEY,
  value BLOB NOT NULL
) STRICT, WITHOUT ROWID;

CREATE TABLE spaces (
  space_rowid INTEGER PRIMARY KEY,
  space_id    BLOB NOT NULL UNIQUE CHECK(length(space_id) = 16),
  kind        INTEGER NOT NULL,
  page_order  INTEGER,
  width       REAL,
  height      REAL,
  revision    INTEGER NOT NULL CHECK(revision >= 0),
  CHECK(width IS NULL OR width > 0),
  CHECK(height IS NULL OR height > 0)
) STRICT;

CREATE TABLE elements (
  element_rowid   INTEGER PRIMARY KEY,
  element_id      BLOB NOT NULL UNIQUE CHECK(length(element_id) = 16),
  space_rowid     INTEGER NOT NULL,
  kind            INTEGER NOT NULL,
  z_order         INTEGER NOT NULL,
  min_x           REAL NOT NULL,
  min_y           REAL NOT NULL,
  max_x           REAL NOT NULL,
  max_y           REAL NOT NULL,
  payload_version INTEGER NOT NULL CHECK(payload_version > 0),
  payload         BLOB NOT NULL,
  revision        INTEGER NOT NULL CHECK(revision >= 0),
  FOREIGN KEY(space_rowid) REFERENCES spaces(space_rowid) ON DELETE CASCADE,
  CHECK(min_x <= max_x),
  CHECK(min_y <= max_y)
) STRICT;

CREATE INDEX idx_elements_space_z
ON elements(space_rowid, z_order, element_rowid);

CREATE TABLE history (
  seq              INTEGER PRIMARY KEY,
  command_id       BLOB NOT NULL UNIQUE CHECK(length(command_id) = 16),
  command_type     INTEGER NOT NULL,
  forward_payload  BLOB NOT NULL,
  inverse_payload  BLOB NOT NULL,
  before_revision  INTEGER NOT NULL CHECK(before_revision >= 0),
  after_revision   INTEGER NOT NULL CHECK(after_revision > before_revision),
  committed_at_ms  INTEGER NOT NULL
) STRICT;

CREATE TABLE document_state (
  singleton         INTEGER PRIMARY KEY CHECK(singleton = 1),
  document_revision INTEGER NOT NULL CHECK(document_revision >= 0),
  history_cursor    INTEGER NOT NULL,
  active_space_rowid INTEGER,
  updated_at_ms     INTEGER NOT NULL,
  FOREIGN KEY(active_space_rowid) REFERENCES spaces(space_rowid)
) STRICT;

CREATE TABLE view_state (
  space_rowid   INTEGER PRIMARY KEY,
  camera_x      REAL NOT NULL,
  camera_y      REAL NOT NULL,
  camera_zoom   REAL NOT NULL CHECK(camera_zoom > 0),
  active_tool   INTEGER NOT NULL,
  tool_payload  BLOB NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  FOREIGN KEY(space_rowid) REFERENCES spaces(space_rowid) ON DELETE CASCADE
) STRICT;
```

### 28.3 为什么使用 `element_rowid INTEGER PRIMARY KEY`

如果直接写成：

```sql
id BLOB PRIMARY KEY
```

普通 rowid 表会同时维护隐藏 rowid 与 BLOB 唯一索引；改成 `WITHOUT ROWID` 又会让包含大型 payload 的整行围绕 BLOB 主键组织，并失去 incremental BLOB I/O。V1.1 采用：

- `element_rowid`：数据库内部紧凑整数键；
- `element_id`：稳定的 128 位业务 ID；
- `UNIQUE(element_id)`：保持逻辑唯一性；
- R-tree、外键或内部批量操作优先引用整数 rowid；
- FFI 和文档命令永远只暴露稳定 `ElementId`，不把 rowid 当业务身份。

### 28.4 header 与 payload 的一致性

`min_x/min_y/max_x/max_y/kind` 是 payload 的派生 header。它们用于：

- 打开文档时不解码全部点数据即可重建粗粒度索引；
- viewport 预筛选；
- 数据诊断和迁移。

代价是存在重复事实。控制方式不是在各读取位置兜底重算，而是：

- 只有 `ElementCodec` 能生成 payload 与 header；
- `INSERT/UPDATE elements` 必须同时写入两者；
- debug/parity tests 解码 payload 后重新计算 bounds 并比较；
- 不一致时拒绝切换 Rust 为真相源；
- 正常运行中不静默以某一方覆盖另一方。

### 28.5 payload 编码

- 使用显式版本的确定性 binary codec；
- 不把 Rust struct 的内存布局直接写盘；
- Stroke points 在一个 payload 内编码，不做 point-per-row；
- 坐标可以采用局部原点 + delta/quantization，但必须证明误差小于渲染容限；
- pressure、timestamp、tilt 等字段的缺省规则由 codec version 固定；
- 未知 `payload_version` 拒绝可写打开，并先生成只读备份；
- migration 函数必须可重复测试，不能在 decode 函数里散布 fallback。

### 28.6 R*Tree 的位置

V1 默认仍使用 Rust `rstar` 内存索引，不立刻创建 SQLite R*Tree：

- 正常 viewport 与 hit test 不查询数据库；
- SQLite R*Tree 默认坐标为 f32，巨大无限坐标需要额外精度审查；
- 双索引会增加每个命令的事务写入与一致性约束。

只有 benchmark 证明“仅加载 element headers 后重建内存 R-tree”仍不可接受，才增加：

```sql
CREATE VIRTUAL TABLE element_bounds USING rtree(
  element_rowid,
  min_x, max_x,
  min_y, max_y
);
```

如果启用，`elements` 与 `element_bounds` 的更新必须处于同一事务，并新增完整性对照测试。

## 29. Journal mode、同步与 checkpoint 策略

### 29.1 不再把 WAL 当作先验答案

SQLite 默认 rollback journal；WAL 增加了第三类操作 checkpoint，并允许 reader 与 writer 并发，但同一时刻仍只有一个 writer。

当前架构中：

- Rust actor 已经串行所有写入；
- 绝大多数读取来自内存文档；
- Flutter 不直接打开数据库；
- 只有 backup、lazy payload 或维护任务可能需要第二连接。

因此，WAL 是否优于 rollback journal 必须由以下指标决定：

- gesture commit P50/P95/P99/max；
- checkpoint 是否造成 Flutter frame P99 抖动；
- 连续书写时日志文件增长；
- 打开、恢复和备份耗时；
- 强制杀进程与设备重启后的 revision；
- 设备实际文件系统上的同步成本。

### 29.2 必测配置

#### Profile A：WAL，严格提交耐久

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = FULL;
PRAGMA foreign_keys = ON;
```

语义：COMMIT 返回后，SQLite 会额外同步 WAL；在 OS/文件系统正确工作的前提下，目标是承受系统崩溃或断电而不丢失已报告成功的事务。

用途：可靠性基线，也是 V1 cutover 前的默认候选。

#### Profile B：WAL，书写性能优先

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;
```

语义：应用进程崩溃后事务仍可恢复；但系统崩溃或断电可能使最近已经返回成功的事务回滚。数据库在 WAL + NORMAL 下保持一致，但不保证最近事务的断电耐久性。

只有在 Profile A 的同步开销确实破坏书写/编辑尾延迟，并且产品明确接受“极端断电可能丢最后几个命令”时才能采用。

#### Profile C：rollback journal 对照

```sql
PRAGMA journal_mode = PERSIST;
PRAGMA synchronous = FULL;
PRAGMA foreign_keys = ON;
```

PERSIST 复用 rollback journal，避免每次删除文件；它适合单连接、低并发写入的对照实验。若最终要求 rollback mode 在断电后的最严格“成功提交不丢失”语义，还必须额外测试 `DELETE + EXTRA`，因为 `EXTRA` 相对 `FULL` 的额外目录同步只对 DELETE 模式有意义。

### 29.3 禁止配置

V1 真实笔记禁止：

```sql
PRAGMA journal_mode = OFF;
PRAGMA journal_mode = MEMORY;
PRAGMA synchronous = OFF;
```

这些配置只能用于可重复生成的临时 benchmark 数据库，不能用于个人笔记。

### 29.4 WAL checkpoint 调度

SQLite 默认可能在导致 WAL 超过约 1000 页的 COMMIT 上触发自动 PASSIVE checkpoint。该行为虽然通常合理，但可能让某一次手势提交承担额外 I/O，从而恶化 P99。

分两阶段实现：

#### 阶段一：保留默认 auto-checkpoint并测量

- 不提前优化；
- 记录每次 commit 前后 WAL page count；
- 通过 trace 标注 checkpoint；
- 关联 Flutter/Rust 帧时间与 commit P99；
- 证明问题存在后才能改调度。

#### 阶段二：显式 idle checkpoint（仅在证据支持时）

```sql
PRAGMA wal_autocheckpoint = 0;
```

然后由 `DocumentSession` actor 管理：

- 输入停止一段时间后，队列为空时运行 `PASSIVE` checkpoint；
- 应用进入后台、文档切换或干净关闭时尝试 `TRUNCATE`；
- 活跃书写期间禁止 `FULL/RESTART/TRUNCATE`；
- 不保持长期 read transaction，避免 checkpoint starvation；
- 设定基于页数/字节数的 WAL 软上限与硬上限；具体阈值由真机基准决定，不写死为跨设备常量；
- 若连续书写使 WAL 达到硬上限，在下一个完整手势边界安排维护，不在 pointer move 中抢占。

### 29.5 `busy_timeout` 不是架构兜底

writer connection 默认不依赖长 `busy_timeout`：

```sql
PRAGMA busy_timeout = 0;
```

因为正常写入全部经过同一个 actor，内部不应发生锁竞争。若 backup connection 与 writer 短暂冲突，可以在备份操作边界使用短、有限次数的退避；不得在所有 SQL 调用中统一等待数秒，把连接所有权错误隐藏成偶发卡顿。

### 29.6 不预调的 PRAGMA

以下参数不在没有测量前固定：

- `cache_size`；
- `mmap_size`；
- `page_size`；
- `locking_mode=EXCLUSIVE`；
- `auto_vacuum`；
- `journal_size_limit`。

初始使用 bundled SQLite 默认 page size。只有 profiler 证明某项是瓶颈，才通过独立 benchmark 调整。

## 30. 事务、备份、恢复与维护

### 30.1 命令事务原子性

每个完成手势形成一个 `StorageCommit`：

```rust
pub struct StorageCommit {
    pub expected_revision: Revision,
    pub element_mutations: Vec<ElementMutation>,
    pub history_entry: HistoryEntry,
    pub next_history_cursor: i64,
    pub view_state_update: Option<ViewStateUpdate>,
}
```

同一个 SQLite transaction 中必须完成：

1. 校验 `expected_revision`；
2. 插入、更新或删除 elements；
3. 更新所有派生 header；
4. 追加 forward/inverse history；
5. 截断 redo 分支（在 undo 后执行新命令时）；
6. 更新 `document_state.document_revision`；
7. 更新 history cursor；
8. 必要时更新 view/session state；
9. COMMIT。

只有 COMMIT 成功后才发布稳定 `DocumentDelta`。失败时保留前端临时预览，但后端权威状态不得前进。

### 30.2 事务大小

- 一条完整笔画：一个短事务；
- 一次整笔擦除手势：所有删除合并为一个事务；
- 一次局部橡皮手势：旧笔画删除与所有片段插入为一个事务；
- 一次选区移动：全部 element 更新为一个事务；
- 不把一个手势拆成数百次 COMMIT；
- 也不把长时间会话积累成一个巨型事务。

### 30.3 备份

活跃数据库备份使用二选一：

1. **SQLite Online Backup API**：支持增量复制，短时间占用源数据库；适合常规版本备份。
2. **`VACUUM INTO`**：生成逻辑一致且压缩后的新数据库；CPU/I/O 更高，适合明确的导出或深度维护。

禁止：

- 数据库打开且处于 WAL 模式时只复制 `.notedb`；
- 手工拼接主文件、WAL 和 SHM；
- 备份过程中让 UI 直接访问第二连接；
- 用成功复制文件大小替代 SQLite 一致性检查。

备份完成后必须：

```text
open backup read-only
-> PRAGMA quick_check
-> PRAGMA foreign_key_check
-> application semantic validation
-> 记录 source revision 与 backup hash
```

### 30.4 完整性检查层级

#### 快速检查

在下列情况执行：

- 非干净关闭后的首次打开；
- 导入外部 `.notedb`；
- 恢复备份；
- SQLite 版本或 schema migration 后。

```sql
PRAGMA quick_check;
PRAGMA foreign_key_check;
```

`quick_check` 比完整 `integrity_check` 快，但不验证 UNIQUE 与索引内容完全一致；foreign key 需要单独检查。

#### 完整检查

在显式维护、生成长期备份或发现异常时执行：

```sql
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

完整检查不能替代应用语义检查。还必须验证：

- payload 可按声明版本解码；
- bounds 与 payload 重算结果一致；
- history revision 连续；
- history cursor 不越界；
- `document_state` revision 与最后提交一致；
- 每个 element 的 space 存在；
- Rust R-tree 重建结果覆盖所有元素。

### 30.5 维护与文件增长

- 不默认开启 `auto_vacuum`；它会引入额外页移动与写放大。
- 删除产生的空闲页优先由后续写入复用，文件不立即缩小不是错误。
- 常规关闭可运行 `PRAGMA optimize`，但必须测量并限制在非活跃书写阶段。
- 只有用户明确执行“压缩/导出备份”或文件膨胀达到测量阈值时才执行 `VACUUM`/`VACUUM INTO`。
- WAL/PERSIST journal 的保留大小由 `journal_size_limit` 控制的必要性需要基准证明，不能为了目录看起来干净而频繁截断并增加 I/O。

### 30.6 故障测试矩阵

对每个候选 profile 执行相同 command trace：

- 进程强杀发生在 BEGIN 前、写入中、COMMIT 前、COMMIT 返回后；
- Android force-stop；
- 应用后台冻结与恢复；
- 设备重启；
- 存储空间不足；
- backup 与正常提交并发；
- checkpoint 前、中、后强杀；
- migration 中断；
- 10k 次写、擦、套索、undo/redo 随机序列。

恢复后比较：

```text
SQLite quick/integrity check
+ foreign_key_check
+ document revision
+ canonical document hash
+ history cursor
+ payload semantic validation
```

不得只检查“数据库可以打开”。

## 31. Rust backend actor

```rust
pub enum BackendMsg {
    Apply(Command, Reply<DocumentDelta>),
    Undo(Reply<DocumentDelta>),
    Redo(Reply<DocumentDelta>),
    QueryViewport(ViewportQuery, Reply<ViewportSnapshot>),
    CreateBackup(BackupRequest, Reply<BackupReceipt>),
    CheckIntegrity(IntegrityLevel, Reply<IntegrityReport>),
    Checkpoint(CheckpointReason, Reply<CheckpointReport>),
    Close(Reply<()>),
}
```

一个线程/任务拥有：

- SQLite writer connection；
- Document；
- RTree；
- history cursor；
- revision；
- journal/checkpoint 状态；
- backup 与 maintenance 排程。

这样不需要在各函数内部不断增加 mutex fallback。并发请求在入口排队，CPU 重几何任务可在只读 snapshot 上并行计算，最终提交回 actor 时再次验证 revision。

## 32. Butterfly 兼容迁移

### 32.1 Shadow 阶段

- 原 `.bfly/.tbfly` 仍为主文件；
- Rust 使用 sidecar SQLite test DB；
- 每次命令比较状态；
- 不覆盖用户真实文件；
- sidecar 使用与候选正式 profile 相同的 schema 和事务语义。

### 32.2 Cutover

1. 导入 Butterfly 2.5.3 文档到 `.notedb`；
2. 生成 canonical hash；
3. 运行 `quick_check`、`foreign_key_check` 与应用语义检查；
4. 通过 Online Backup API 或 `VACUUM INTO` 生成 cutover 前备份；
5. 打开并渲染所有 fixture；
6. 将原 Butterfly 文件保留为只读备份；
7. SQLite 目标 DB 成为真相；
8. 如需回到 Butterfly，通过 compat exporter 明确导出，不做双向实时同步。

---

# 第七部分：渲染与性能

## 33. 实时路径性能不变量

活动笔画每帧不得执行：

- 查询整份文档；
- 序列化文档；
- SQLite write；
- 重建所有 Renderer；
- 全 viewport bake；
- 同步等待 Rust 几何；
- 同步刷新缩略图。

目标复杂度：

```text
active frame = O(current stroke incremental work + small foreground set)
```

不能是：

```text
active frame = O(all historical strokes)
```

## 34. 先保留 Baking，再用证据决定 Tile Cache

### 34.1 第一阶段

保留 Butterfly baked image + visible-unbaked 架构，但让 Rust `DocumentDelta` 提供：

```text
created IDs
updated IDs
removed IDs
dirty bounds
space revision
```

避免因为一次局部命令调用 `loadElements(current)` 或全量刷新。

### 34.2 Tile Cache 触发门槛

只有出现以下任一情况才实现：

- bake P95 超过一个 120 Hz 帧预算，并在编辑后阻塞前景；
- viewport image 尺寸导致内存随缩放明显增长；
- 大画布平移频繁重 bake；
- 局部 dirty bounds 仍引发大面积重建。

这些现象必须在真实 document canvas、同一 fixture/replay 和关闭无关观测开销的
Profile 对照中归因到 stable renderer/bake owner。仅看到总帧 P99、内存增长或
编辑后卡顿，尚不足以判定 tile cache；应先排除输入、命令、DB、几何和全量错误失效。
未触发时 M8 的正确结论是“保留 Baking”，不是继续实现。

### 34.3 目标 tile 设计

```text
TileKey(spaceId, zoomBucket, tileX, tileY, contentRevision)
```

- 512 physical px 为初始候选，必须 benchmark 256/512/1024；
- zoom bucket 使用离散倍率；
- dirty bounds 只使相交 tile 失效；
- LRU 限制 GPU/CPU cache；
- 活动笔画永远在 tile 上方；
- 缺 tile 时可暂时显示低分辨率父级，不阻塞输入。

## 35. Jetpack Ink Spike

若触发 M7：

触发证据必须先把首个超标位置归因到 active ink owner：历史样本在 native 已存在但
当前 Flutter 消费链丢失，或 foreground update 持续主导预冻结的延迟/P99 门槛。
光学录像用于裁决端到端显示延迟；Pencil 快捷键和掌托精确语义不是该 Spike 的前置条件，
除非 Spike 同时改变它们的路由。

1. 在 Butterfly 2.5.3 的 Flutter 3.44.1 上建立 Android native overlay 实验；
2. 检查 OPPO Pad 4 Pro 的 Vulkan/Impeller 与 HCPP；
3. `InProgressStrokesView.eagerInit()`；
4. stylus stream 调用 `requestUnbufferedDispatch`；
5. MotionEventPredictor 生成预测点；
6. finished stroke 一次提交给 Rust；
7. dry stroke 进入 Flutter stable layer 后调用 `removeFinishedStrokes`。

必须独立验证：

- 透明叠层；
- Flutter toolbar 遮罩与 Ink `maskPath`；
- finger gesture 路由；
- 相机矩阵同步；
- wet/dry 笔刷一致；
- HCPP fallback 后性能。

若这一 Spike 不能清晰优于 Flutter 前景路径，不合并。

---

# 第八部分：基准、测试与验收

## 36. 基准文档

建立确定性生成器：

| fixture | 内容 |
|---|---|
| F0 | 0 strokes |
| F1 | 1,000 strokes，普通一页 |
| F10 | 10,000 strokes，密集公式/小字 |
| F50 | 50,000 strokes，大文档 |
| F200 | 200,000 strokes，极限压力 |
| FLONG | 单条 20,000 samples 的长笔画 |
| FFRAG | partial eraser 产生大量 fragments |
| FPAGE | 100 pages，每页固定笔画数 |

生成器 seed 固定；fixture 与期待 hash 提交仓库。

## 37. 六类红线对应指标

### 37.1 墨迹明显落后笔尖

帧指标不能直接代表端到端笔尖延迟。采用：

- 240/480 fps 外部相机同时拍摄笔尖与屏幕；
- 同一设备、同一书写动作，对比 Notein、Butterfly baseline、当前 build；
- 记录触屏接触到首像素、运动中最大 gap 和抬笔尾部收敛。

目标不是相信厂商“2 ms”宣传，而是取得同条件相对数据。

### 37.2 样本丢失/形变

- 原生 sample + history 总数；
- Flutter/Jetpack Ink 消费总数；
- raw_points 总数；
- 明确去重数；
- 不允许未解释差值。

### 37.3 随笔画数退化

在 F0/F1/F10/F50 中执行同一 10 秒书写轨迹，比较：

- P50/P90/P95/P99 frame time；
- foreground build/raster；
- backend call；
- stable cache invalidation。

目标：历史笔画从 1k 增到 50k 时，活动笔画关键路径不出现显著线性增长。初始门槛可设为 P95 增幅不超过 10%，再由真实基线校准。

### 37.4 pan/zoom jank

使用 Android Macrobenchmark FrameTimingMetric、Flutter FrameTiming 和 Perfetto：

- 120 Hz 下预算 8.33 ms；
- 报告 P50/P90/P95/P99 与 missed frames；
- 区分 UI/build、raster、platform composition。

### 37.5 编辑后持续退化

脚本：

```text
write -> erase -> write -> lasso -> move -> write -> undo -> write
```

每个 write 区段比较帧分布；后续区段不得因为 cache state 错误持续变慢。

### 37.6 undo pause

分别测：

- undo 1 stroke；
- undo 500-element translate；
- undo partial erase with fragments；
- 连续 undo/redo 100 次。

UI 不等待整份文档序列化；delta 与 stable cache 更新必须局部化。

## 38. 测试层级

1. **Rust unit**：命令、不变量、geometry、codec、migration。
2. **Property tests**：undo(command(state)) == state；partial erase fragments 不落在擦除区；R-tree 与 brute-force 候选一致。
3. **Parity tests**：Legacy 与 Rust 对固定命令序列的 canonical state。
4. **Golden tests**：固定 zoom 下 SVG/PNG；允许视觉容差，但不能只看像素不看语义。
5. **Flutter integration**：pointer routing、foreground-to-dry handoff、toolbar temporary tool。
6. **Android device tests**：Pencil 2、history samples、button、palm、refresh rate。
7. **Macrobenchmark/Perfetto**：profile/release build，只在真机。
8. **Crash consistency**：在 transaction 前、中、后强制杀进程并重启。

---

# 第九部分：工程组织与防耦合规则

## 39. 分支策略

```text
baseline/v2.5.3-pristine       # 不可修改
baseline/v2.5.3-instrumented   # 只加测量
refactor/backend-interface     # Legacy adapter
rust/shadow-backend
rust/authoritative-minimal
feature/partial-eraser
feature/paged-mode
experiment/jetpack-ink
experiment/tile-cache
```

### 39.1 上游同步

每个上游 patch 必须分类：

- A：安全/Android 崩溃/构建修复，可评估 cherry-pick；
- B：UI 孤立修复，可选；
- C：DocumentBloc、CurrentIndex、state management、file format 大改，默认不合并；
- D：新功能，V1 不合并。

## 40. 模块依赖规则

允许：

```text
UI -> application protocol -> backend interface
backend -> core/geometry/storage
renderer -> immutable render DTO
```

禁止：

```text
Rust core import Flutter concepts
UI directly query SQLite
geometry hold Renderer references
storage choose active tool
handler modify element list directly
unknown error silently fabricate default document
```

## 41. 防御性编程边界

只在以下边界验证：

- Butterfly import；
- DB decode/migration；
- FFI DTO；
- Android MotionEvent 转换；
- 用户输入的笔刷参数。

验证后构造强类型对象：

```rust
ValidatedStroke
NonEmptyPoints
FiniteAabb
KnownBrushId
DocumentRevision
```

内部函数信任这些类型。异常由拥有者解决，不在下游加层层 fallback。

---

# 第十部分：阶段交付物与决策门

## 42. 每个阶段必须产出

### M0

- 固定源码 tag 与 toolchain；
- baseline APK；
- requirements baseline + hash；
- test fixture generator；
- source ledger。

### M1

- OPPO 设备能力 JSON；
- 综合输入 trace 与未证明语义清单；
- Legacy 行为 oracle 与 owner-boundary replay；
- 空文档和代表性压力文档的三轮 pre-M2 Profile 基线；
- 冻结的 M2 行为/回归裁决规则。

### M2

- `DocumentBackend`；
- Legacy adapter；
- ID-based selection；
- command/delta model；
- 与 Legacy oracle 逐命令一致的 integration tests；
- 同 fixture/replay 的定向性能回归报告。

### M3

- Rust workspace；
- FRB bridge；
- shadow executor；
- canonical diff report；
- 零未解释差异的 parity gate；
- Shadow 资源上限与开启开销报告。

### M4

- `.notedb`；
- Rust authority for create/remove/undo；
- infinite minimal prototype；
- crash consistency report；
- performance report。
- SQLite 配置、故障恢复与单 writer/回退报告。

### M5

- continuous partial eraser；
- lasso；
- translate；
- operation-after-performance regression suite。
- 每项独立语义、事务和回退证据。

### M6

- paged mode；
- resume；
- minimal Notein-inspired toolbar；
- V1 acceptance report。
- 文档模式、session 与 UI owner-boundary 验收。

## 43. 决策门

### Gate A：是否引入 Jetpack Ink

只有 Flutter active path 在同 fixture/replay 的 Profile 与必要的光学证据中未达标，
且首个超标 owner 已定位到活动墨迹链，才进入；否则保持 Flutter。

### Gate B：是否实现 tile cache

只有正确 dirty bounds 下 Baking/stable renderer 仍被同路径对照证明为瓶颈才进入；
否则保留现有 Baking。

### Gate C：Rust 是否成为真相

按命令子集切换：只有将要接管的命令全部通过 Shadow parity，且未迁移写功能关闭、
单 writer 与回退边界成立，Rust 才成为该子集的真相。无需等待尚未接管的全部 V1 功能。

### Gate D：SQLite 文档是否切换为真实笔记真相源

只有以下条件全部满足才切换真实笔记：

- schema migration 与 Butterfly 导入 parity 通过；
- 选定的 journal/synchronous profile 在 OPPO Pad 4 Pro 上通过耐久与 P99 测试；
- quick/integrity/foreign-key 与应用语义检查通过；
- Online Backup API 或 `VACUUM INTO` 的回滚备份可验证恢复；
- kill、force-stop、checkpoint 与 migration 中断测试通过。

---

# 第十一部分：风险台账

| 风险 | 后果 | 早期信号 | 处理 |
|---|---|---|---|
| OPPO 快捷键不暴露 down/up | 无法实现按住临时擦除 | Probe 只有 double-tap/无事件 | 明确硬件阻塞；实现真实可得语义，不伪装 |
| Flutter 丢历史采样 | 快写变形 | native count > Flutter count | 批量 native input 或 Jetpack Ink gate |
| Bloc/Renderer 耦合比预期深 | Shadow 迁移拖延 | Backend interface 仍返回 Renderer | 先 ID 化 selection/raycast，禁止 Rust 认识 Renderer |
| 2.6 上游状态重构冲突 | 双重迁移 | 大量 merge conflict | 固定 2.5.3，只 cherry-pick 孤立修复 |
| partial eraser fragment explosion | DB/渲染退化 | fragment 数持续增长 | 几何合并、tiny fragment policy、单手势一次重建 |
| DB transaction 进入实时路径 | 写字卡顿 | trace 显示 move 中 SQLite | 只在 gesture commit 写事务 |
| WAL 自动 checkpoint 落在手势提交上 | 偶发 P99 暂停 | commit trace 与 checkpoint 同时出现 | 先测默认；有证据后改为 actor idle checkpoint |
| 活跃 WAL 数据库只复制主文件 | 备份缺少最近事务或不可恢复 | 备份 revision 低于源库 | 仅用 Online Backup API / `VACUUM INTO` |
| element header 与 payload 分叉 | hit test、渲染和恢复不一致 | bounds parity test 失败 | 统一 codec 生成，同事务写入，拒绝静默修复 |
| `busy_timeout` 隐藏多连接竞争 | 随机卡顿难以定位 | 正常 commit 出现 SQLITE_BUSY/等待 | 单 actor 独占 writer；正常写入 busy=0 |
| Rust FFI 过细 | 延迟和锁竞争 | 每帧大量 bridge call | 完整 stroke/command 粗粒度接口 |
| Jetpack Ink platform view 手势冲突 | finger navigation 不稳定 | gesture arena/HCPP trace | 独立实验，未胜出不合并 |
| “无永久非目标”引发范围漂移 | 第一版无限膨胀 | 新功能无基准关联 | V1 scope freeze；新增需求升版本 |
| 过度兼容旧 Butterfly | 核心一直被旧格式限制 | 每个命令都有双模型分支 | compat 层只在导入/导出边界存在 |

---

# 第十二部分：变更控制

## 44. 三类变更

### 44.1 需求澄清

不改变用户意图，只把未定义语义固定下来，例如“套索选择相交还是完全包含”。必须新增 Decision Record，但 baseline 原文不变。

### 44.2 需求变更

改变 V1 功能、优先级或设备范围。必须：

1. 更新 `REQUIREMENTS_BASELINE_V*.json`；
2. 版本号至少 minor bump；
3. 保存旧文件；
4. 写出为何改变与影响哪些阶段。

### 44.3 实现变更

例如从 Baking 改成 tile cache，不改变用户行为。只更新技术计划与 decision ledger，不改原始需求。

## 45. 每次计划迭代必须回答

1. 是否改变了原始动机？
2. 是否把 Deferred 功能偷偷加入 V1？
3. 是否为了复用上游而接受了用户明确反感的耦合？
4. 是否在没有 benchmark 的情况下宣称性能更好？
5. 是否把硬件未知当成已知能力？
6. 是否仍能从原始 Grill JSON 追溯每个产品决策？

---

# 附录 A：原始 Grill 第一轮问题

<details>
<summary>展开原始 JSON</summary>

```json
{
  "protocol": "chatgpt-grill/v1",
  "id": "note-dev-requirements-01",
  "title": "Android 手写笔记软件需求梳理",
  "description": "这些问题用于确定产品定位、内核路线、性能目标和第一版开发边界。可只排序或选择你真正关心的内容。",
  "submit_label": "提交并继续",
  "review_before_submit": true,
  "questions": [
    {
      "id": "release_scope",
      "header": "项目定位",
      "question": "你预计这个项目最终以什么形式存在？",
      "description": "这会影响兼容性投入、插件安全边界、升级机制和代码维护方式。",
      "type": "single_select",
      "required": true,
      "options": [
        {
          "label": "仅供自己使用",
          "value": "personal_only",
          "description": "只适配自己的平板和工作流，可以大胆修改并减少兼容性成本。",
          "recommended": true
        },
        {
          "label": "分享给少量熟人使用",
          "value": "small_private_group",
          "description": "需要基本的稳定性、迁移和多设备兼容。"
        },
        {
          "label": "公开开源发布",
          "value": "public_open_source",
          "description": "需要文档、通用配置、版本迁移和更广泛设备支持。"
        },
        {
          "label": "未来可能商业化",
          "value": "possible_commercial",
          "description": "需要更严格考虑许可证、模块边界和产品化架构。"
        }
      ],
      "allow_other": false
    },
    {
      "id": "target_hardware",
      "header": "目标设备",
      "question": "请填写主要测试设备信息。",
      "description": "手写延迟、预测、侧键、掌托和高刷新率表现高度依赖具体设备。",
      "type": "fill_blanks",
      "required": true,
      "blanks": [
        {
          "id": "tablet_model",
          "label": "平板品牌与型号",
          "placeholder": "例如 Samsung Galaxy Tab S9+",
          "required": true,
          "multiline": false,
          "max_length": 100
        },
        {
          "id": "android_version",
          "label": "Android 版本",
          "placeholder": "例如 Android 16",
          "required": false,
          "multiline": false,
          "max_length": 50
        },
        {
          "id": "stylus",
          "label": "手写笔型号与能力",
          "placeholder": "例如 S Pen，支持压力、悬停、侧键、笔尾橡皮擦",
          "required": true,
          "multiline": false,
          "max_length": 160
        },
        {
          "id": "screen_refresh",
          "label": "屏幕刷新率",
          "placeholder": "例如 120 Hz",
          "required": false,
          "multiline": false,
          "max_length": 40
        },
        {
          "id": "secondary_devices",
          "label": "是否还需兼容其他设备",
          "placeholder": "例如 Windows 查看、Android 手机只读，或完全不需要",
          "required": false,
          "multiline": true,
          "max_length": 240
        }
      ]
    },
    {
      "id": "primary_workflows",
      "header": "使用场景",
      "question": "第一阶段必须支持哪些核心工作流？",
      "description": "最多选择 5 项。未选择的功能可以延后，不代表永远不做。",
      "type": "multi_select",
      "required": true,
      "min_selections": 1,
      "max_selections": 5,
      "options": [
        {
          "label": "课堂或自学手写笔记",
          "value": "handwritten_study_notes",
          "description": "长时间连续书写、分页、模板、公式和图示。"
        },
        {
          "label": "PDF 阅读与批注",
          "value": "pdf_annotation",
          "description": "导入教材、试卷、论文并直接书写和摘录。"
        },
        {
          "label": "无限画布与自由排版",
          "value": "infinite_canvas",
          "description": "思维导图、推导过程、自由缩放和大范围布局。"
        },
        {
          "label": "手写与文本混排",
          "value": "mixed_handwriting_text",
          "description": "Markdown、代码、公式、图片与笔迹共同存在。"
        },
        {
          "label": "题目整理与错题本",
          "value": "problem_workflow",
          "description": "截图、裁剪、答案折叠、标签和题目来源链接。"
        },
        {
          "label": "知识库与双向链接",
          "value": "knowledge_base",
          "description": "页面引用、反向链接、标签、搜索和关系组织。"
        },
        {
          "label": "会议记录或录音同步",
          "value": "meeting_audio",
          "description": "录音时间轴与笔迹时间戳关联。"
        },
        {
          "label": "演示、白板与激光笔",
          "value": "presentation_whiteboard",
          "description": "投屏、演示模式、临时标记和协作展示。"
        },
        {
          "label": "AI、OCR 与数学识别",
          "value": "ai_ocr_math",
          "description": "对选区或页面执行识别、总结、检索和结构化处理。"
        }
      ],
      "allow_other": true
    },
    {
      "id": "document_model",
      "header": "文档形态",
      "question": "你希望默认采用哪种笔记空间模型？",
      "description": "这是影响渲染、存储、导航和 PDF 工作流的基础决策。",
      "type": "single_select",
      "required": true,
      "options": [
        {
          "label": "传统分页笔记本",
          "value": "paged_notebook",
          "description": "类似 Goodnotes、Samsung Notes，每页尺寸固定，适合打印与 PDF。"
        },
        {
          "label": "纯无限画布",
          "value": "infinite_canvas_only",
          "description": "没有固定页面边界，强调自由布局和缩放。"
        },
        {
          "label": "分页与无限画布并存",
          "value": "hybrid_modes",
          "description": "每个文档可选择分页或无限画布，能力最完整但实现复杂。",
          "recommended": true
        },
        {
          "label": "PDF 为主、空白笔记为辅",
          "value": "pdf_first",
          "description": "重点优化教材、论文和试卷批注。"
        },
        {
          "label": "连续纵向长纸",
          "value": "continuous_vertical",
          "description": "类似一张无限向下延伸的纸，但宽度固定。"
        }
      ],
      "allow_other": true
    },
    {
      "id": "priority_ranking",
      "header": "优先级",
      "question": "请按重要程度排序最关键的目标。",
      "description": "最多排序 6 项，不需要给其余候选项强行排位。",
      "type": "ranking",
      "required": true,
      "min_ranked": 3,
      "max_ranked": 6,
      "options": [
        {
          "label": "笔迹低延迟与跟手性",
          "value": "ink_latency"
        },
        {
          "label": "满页和大文档仍保持流畅",
          "value": "large_document_performance"
        },
        {
          "label": "笔刷手感、压力和线条质量",
          "value": "stroke_quality"
        },
        {
          "label": "PDF 导入、批注与导出",
          "value": "pdf_workflow"
        },
        {
          "label": "套索、橡皮擦、撤销等编辑体验",
          "value": "editing_tools"
        },
        {
          "label": "崩溃恢复与数据可靠性",
          "value": "data_reliability"
        },
        {
          "label": "功能可扩展和可编程",
          "value": "extensibility"
        },
        {
          "label": "开放文件格式与可迁移性",
          "value": "open_format"
        },
        {
          "label": "跨设备同步",
          "value": "sync"
        },
        {
          "label": "界面美观与操作效率",
          "value": "ui_ux"
        },
        {
          "label": "OCR、AI 和自动化能力",
          "value": "ai_automation"
        }
      ]
    },
    {
      "id": "performance_target",
      "header": "性能标准",
      "question": "你希望第一版达到哪一级性能目标？",
      "description": "更高目标可能要求替换 Flutter 实时墨迹层，接入 Jetpack Ink 或原生渲染。",
      "type": "single_select",
      "required": true,
      "options": [
        {
          "label": "能稳定日常使用即可",
          "value": "practical_daily",
          "description": "普通课堂笔记和 PDF 批注流畅，极端大文档允许降级。"
        },
        {
          "label": "明显优于现有开源软件",
          "value": "better_than_open_source",
          "description": "密集满页、连续书写、套索和撤销均不能频繁卡顿。",
          "recommended": true
        },
        {
          "label": "接近 Samsung Notes 级跟手性",
          "value": "near_native_commercial",
          "description": "将低延迟视为核心指标，接受原生 Kotlin、Jetpack Ink 或 C++ 混合架构。"
        },
        {
          "label": "优先极限性能，不惜大幅重构",
          "value": "maximum_performance",
          "description": "以高刷新率、超大文档和严格帧时间为目标，功能开发可延后。"
        }
      ],
      "allow_other": false
    },
    {
      "id": "extensibility_level",
      "header": "自定义方式",
      "question": "你期望以后如何给软件增加功能？",
      "description": "这决定是否需要命令注册表、运行时脚本、插件 API 和权限隔离。",
      "type": "single_select",
      "required": true,
      "options": [
        {
          "label": "直接修改源码并重新编译",
          "value": "source_modification",
          "description": "最简单，适合仅自己使用，但功能容易与核心代码耦合。"
        },
        {
          "label": "内部模块与注册表",
          "value": "internal_extension_registry",
          "description": "新工具、命令和元素通过统一接口注册，仍需重新编译。",
          "recommended": true
        },
        {
          "label": "应用内脚本系统",
          "value": "runtime_scripting",
          "description": "使用 Lua、JavaScript 或其他脚本直接编写自动化和处理逻辑。"
        },
        {
          "label": "完整第三方插件系统",
          "value": "external_plugin_system",
          "description": "允许独立插件包安装、启停和升级，复杂度与安全成本最高。"
        },
        {
          "label": "内部扩展加脚本系统",
          "value": "registry_plus_scripting",
          "description": "核心工具使用类型安全接口，个人自动化使用脚本。"
        }
      ],
      "allow_other": true
    },
    {
      "id": "development_constraints",
      "header": "开发边界",
      "question": "请填写影响技术路线的实际约束。",
      "description": "这些信息将用于决定直接 Fork Butterfly、改造 Saber，还是采用原生/混合内核。",
      "type": "fill_blanks",
      "required": true,
      "blanks": [
        {
          "id": "languages_frameworks",
          "label": "愿意使用的语言与框架",
          "placeholder": "例如 Kotlin、Flutter/Dart、C++、React Native 均可",
          "required": true,
          "multiline": true,
          "max_length": 300
        },
        {
          "id": "unacceptable_stack",
          "label": "不能接受的技术或维护负担",
          "placeholder": "例如不想碰 C++、不接受 React Native、不要服务器",
          "required": false,
          "multiline": true,
          "max_length": 300
        },
        {
          "id": "weekly_time",
          "label": "预计每周投入时间",
          "placeholder": "例如每周 8 小时",
          "required": true,
          "multiline": false,
          "max_length": 80
        },
        {
          "id": "first_milestone",
          "label": "第一版必须具备的功能",
          "placeholder": "例如稳定手写、分页、PDF、套索、自动保存，其他全部延后",
          "required": true,
          "multiline": true,
          "max_length": 600
        },
        {
          "id": "storage_sync_export",
          "label": "存储、同步与导出要求",
          "placeholder": "例如本地文件夹为真相源，WebDAV 同步，必须导出 PDF/SVG/PNG",
          "required": true,
          "multiline": true,
          "max_length": 500
        },
        {
          "id": "special_features",
          "label": "你最想自行添加的特殊功能",
          "placeholder": "请列出商业软件迟迟没有实现、但你最需要的功能",
          "required": false,
          "multiline": true,
          "max_length": 800
        }
      ]
    }
  ]
}
```

</details>

# 附录 B：原始 Grill 第一轮回答

<details>
<summary>展开原始 JSON</summary>

```json
{
  "protocol": "chatgpt-grill-response/v1",
  "in_reply_to": "note-dev-requirements-01",
  "answers": [
    {
      "question_id": "release_scope",
      "question": "你预计这个项目最终以什么形式存在？",
      "type": "single_select",
      "values": [
        "personal_only"
      ],
      "labels": [
        "仅供自己使用"
      ]
    },
    {
      "question_id": "target_hardware",
      "question": "请填写主要测试设备信息。",
      "type": "fill_blanks",
      "fields": [
        {
          "id": "tablet_model",
          "label": "平板品牌与型号",
          "value": "Oppo Pad 4 Pro"
        },
        {
          "id": "android_version",
          "label": "Android 版本",
          "value": "16"
        },
        {
          "id": "stylus",
          "label": "手写笔型号与能力",
          "value": "Oppo Pen 2"
        },
        {
          "id": "screen_refresh",
          "label": "屏幕刷新率",
          "value": "120"
        },
        {
          "id": "secondary_devices",
          "label": "是否还需兼容其他设备",
          "value": "不需要"
        }
      ]
    },
    {
      "question_id": "primary_workflows",
      "question": "第一阶段必须支持哪些核心工作流？",
      "type": "multi_select",
      "values": [
        "handwritten_study_notes",
        "infinite_canvas"
      ],
      "labels": [
        "课堂或自学手写笔记",
        "无限画布与自由排版"
      ]
    },
    {
      "question_id": "document_model",
      "question": "你希望默认采用哪种笔记空间模型？",
      "type": "single_select",
      "values": [
        "hybrid_modes"
      ],
      "labels": [
        "分页与无限画布并存"
      ]
    },
    {
      "question_id": "priority_ranking",
      "question": "请按重要程度排序最关键的目标。",
      "type": "ranking",
      "ranking": [
        {
          "rank": 1,
          "value": "large_document_performance",
          "label": "满页和大文档仍保持流畅"
        },
        {
          "rank": 2,
          "value": "ink_latency",
          "label": "笔迹低延迟与跟手性"
        },
        {
          "rank": 3,
          "value": "stroke_quality",
          "label": "笔刷手感、压力和线条质量"
        },
        {
          "rank": 4,
          "value": "editing_tools",
          "label": "套索、橡皮擦、撤销等编辑体验"
        },
        {
          "rank": 5,
          "value": "ui_ux",
          "label": "界面美观与操作效率"
        },
        {
          "rank": 6,
          "value": "data_reliability",
          "label": "崩溃恢复与数据可靠性"
        }
      ],
      "unranked_values": [
        "pdf_workflow",
        "extensibility",
        "open_format",
        "sync",
        "ai_automation"
      ]
    },
    {
      "question_id": "performance_target",
      "question": "你希望第一版达到哪一级性能目标？",
      "type": "single_select",
      "values": [
        "better_than_open_source"
      ],
      "labels": [
        "明显优于现有开源软件"
      ]
    },
    {
      "question_id": "extensibility_level",
      "question": "你期望以后如何给软件增加功能？",
      "type": "single_select",
      "values": [
        "internal_extension_registry"
      ],
      "labels": [
        "内部模块与注册表"
      ]
    },
    {
      "question_id": "development_constraints",
      "question": "请填写影响技术路线的实际约束。",
      "type": "fill_blanks",
      "fields": [
        {
          "id": "languages_frameworks",
          "label": "愿意使用的语言与框架",
          "value": "任意，略微偏好Rust"
        },
        {
          "id": "unacceptable_stack",
          "label": "不能接受的技术或维护负担",
          "value": "模块强耦合，过度防御性编程"
        },
        {
          "id": "weekly_time",
          "label": "预计每周投入时间",
          "value": "可持续投入时间"
        },
        {
          "id": "first_milestone",
          "label": "第一版必须具备的功能",
          "value": "参考先前的回答"
        },
        {
          "id": "storage_sync_export",
          "label": "存储、同步与导出要求",
          "value": "无，可实现基础功能但不是重点"
        },
        {
          "id": "special_features",
          "label": "你最想自行添加的特殊功能",
          "value": ""
        }
      ]
    }
  ]
}
```

</details>

# 附录 C：原始 Grill 第二轮问题

<details>
<summary>展开原始 JSON</summary>

```json
{
  "protocol": "chatgpt-grill/v1",
  "id": "note-dev-requirements-02",
  "title": "Android 手写笔记软件深度需求审查",
  "description": "这一轮只追问会改变内核、交互或开发计划的关键决策。回答将与上一轮原始问答一起原样保留在最终计划中，作为后续迭代的需求基线。",
  "submit_label": "提交并生成详细计划",
  "review_before_submit": true,
  "questions": [
    {
      "id": "foundation_strategy",
      "header": "基础路线",
      "question": "你接受哪种项目起步方式？",
      "description": "这决定最终计划是围绕 Butterfly 深改，还是围绕原生新内核展开。后续仍会把 Butterfly、Saber、Jetpack Ink 等作为对照和参考。",
      "type": "single_select",
      "required": true,
      "options": [
        {
          "label": "先做独立性能原型，再决定 Fork 或重写",
          "value": "benchmark_first",
          "description": "分别验证 Jetpack Ink、Butterfly 和必要的 Rust 模块，以数据决定最终主线。",
          "recommended": true
        },
        {
          "label": "直接新建 Kotlin + Jetpack Ink 项目",
          "value": "greenfield_native",
          "description": "不继承现有应用架构，只选择性参考其实现。"
        },
        {
          "label": "以 Butterfly 为主仓库逐步重构",
          "value": "butterfly_mainline",
          "description": "优先保留已有编辑器、文档和 UI，再替换性能瓶颈。"
        },
        {
          "label": "维护 Butterfly Fork，同时另建原生内核",
          "value": "dual_track",
          "description": "一个分支尽快可用，一个分支探索最终架构；开发成本最高。"
        }
      ],
      "allow_other": false
    },
    {
      "id": "writing_tools",
      "header": "书写工具",
      "question": "第一版必须具备哪些笔与输入行为？",
      "description": "最多选择 7 项。未选功能将明确排除在第一版实现计划之外。",
      "type": "multi_select",
      "required": true,
      "min_selections": 1,
      "max_selections": 7,
      "options": [
        {
          "label": "单一压力钢笔",
          "value": "pressure_pen",
          "description": "宽度随压力变化，是第一版默认主笔。",
          "recommended": true
        },
        {
          "label": "固定宽度圆珠笔",
          "value": "monoline_pen",
          "description": "不受压力影响，适合公式和小字。"
        },
        {
          "label": "荧光笔",
          "value": "highlighter",
          "description": "半透明混合，可穿过已有笔迹。"
        },
        {
          "label": "压力曲线可调",
          "value": "pressure_curve",
          "description": "允许调节压力到宽度的映射曲线。"
        },
        {
          "label": "笔迹稳定或平滑强度可调",
          "value": "stroke_smoothing",
          "description": "改变采样滤波、流线和平滑参数。"
        },
        {
          "label": "悬停光标预览",
          "value": "hover_cursor",
          "description": "笔未接触屏幕时显示落笔位置和笔宽。"
        },
        {
          "label": "侧键临时切换橡皮擦",
          "value": "barrel_button_eraser",
          "description": "按住切换、松开恢复原工具。"
        },
        {
          "label": "双击或手势切换工具",
          "value": "stylus_gesture_switch",
          "description": "利用设备实际支持的手写笔事件切换工具。"
        },
        {
          "label": "手指只负责平移和缩放",
          "value": "finger_navigation_only",
          "description": "手写笔绘制，手指不产生笔迹。"
        },
        {
          "label": "允许手指绘制模式",
          "value": "optional_finger_drawing",
          "description": "设置中可临时开启。"
        }
      ],
      "allow_other": true
    },
    {
      "id": "hybrid_document_semantics",
      "header": "文档模型",
      "question": "分页与无限画布应如何共存？",
      "description": "这会决定坐标系、页面裁剪、导出、导航和缓存分块方式。",
      "type": "single_select",
      "required": true,
      "options": [
        {
          "label": "每个文档创建时二选一",
          "value": "mode_per_document",
          "description": "分页文档与无限文档共享元素内核，但交互模式固定，复杂度最低。",
          "recommended": true
        },
        {
          "label": "无限画布中放置页面框",
          "value": "frames_in_infinite_world",
          "description": "页面只是世界坐标中的特殊对象，允许页外书写和跨页元素。"
        },
        {
          "label": "分页文档可随时扩展为无限画布",
          "value": "paged_to_infinite",
          "description": "默认分页，需要时解除边界，转换后仍保留页面框。"
        },
        {
          "label": "同一文档内存在分页区和自由画布区",
          "value": "mixed_regions",
          "description": "能力最强，但导航、导出和选择规则明显更复杂。"
        }
      ],
      "allow_other": true
    },
    {
      "id": "editing_semantics",
      "header": "编辑规则",
      "question": "第一版必须支持哪些编辑语义？",
      "description": "最多选择 7 项。不同橡皮擦和选择语义会显著改变空间索引、几何运算和撤销模型。",
      "type": "multi_select",
      "required": true,
      "min_selections": 2,
      "max_selections": 7,
      "options": [
        {
          "label": "整笔画橡皮擦",
          "value": "stroke_eraser",
          "description": "触碰任意位置即删除整条笔画，性能和实现最可控。",
          "recommended": true
        },
        {
          "label": "局部像素式橡皮擦",
          "value": "partial_eraser",
          "description": "切割笔画并保留未擦除部分，需要可靠的曲线分割。"
        },
        {
          "label": "自由套索选择",
          "value": "freeform_lasso",
          "description": "按闭合路径选择相交或包含的元素。"
        },
        {
          "label": "矩形框选",
          "value": "rectangle_selection",
          "description": "简单且可预测的批量选择。"
        },
        {
          "label": "选区移动",
          "value": "selection_translate",
          "description": "平移所选笔画并更新空间索引。"
        },
        {
          "label": "选区缩放",
          "value": "selection_scale",
          "description": "统一缩放坐标与笔宽。"
        },
        {
          "label": "选区旋转",
          "value": "selection_rotate",
          "description": "对所选元素施加旋转变换。"
        },
        {
          "label": "复制、剪切和粘贴",
          "value": "clipboard_operations",
          "description": "优先支持应用内部剪贴板。"
        },
        {
          "label": "按一次落笔作为一个撤销单位",
          "value": "stroke_level_undo",
          "description": "每条完整笔画对应一个历史命令。"
        },
        {
          "label": "连续编辑自动合并为事务",
          "value": "transaction_coalescing",
          "description": "拖动、缩放等连续动作只产生一个撤销步骤。"
        }
      ],
      "allow_other": true
    },
    {
      "id": "performance_failure_ranking",
      "header": "性能红线",
      "question": "请排序最不可接受的性能问题。",
      "description": "最多排序 6 项。排序结果将决定基准测试、性能预算和阶段验收顺序。",
      "type": "ranking",
      "required": true,
      "min_ranked": 3,
      "max_ranked": 6,
      "options": [
        {
          "label": "墨迹明显落后笔尖",
          "value": "visible_ink_lag"
        },
        {
          "label": "写满一页后延迟持续增加",
          "value": "degrades_with_strokes"
        },
        {
          "label": "快速书写时丢采样点或笔画变形",
          "value": "sample_loss"
        },
        {
          "label": "缩放和平移掉帧",
          "value": "viewport_jank"
        },
        {
          "label": "橡皮擦或套索后持续卡顿",
          "value": "post_edit_degradation"
        },
        {
          "label": "撤销或重做出现长暂停",
          "value": "undo_pause"
        },
        {
          "label": "自动保存打断书写",
          "value": "autosave_jank"
        },
        {
          "label": "大型文档打开过慢",
          "value": "slow_open"
        },
        {
          "label": "长时间使用后内存不断增长",
          "value": "memory_growth"
        }
      ]
    },
    {
      "id": "interaction_workflow",
      "header": "操作体验",
      "question": "请描述你希望的软件操作方式。",
      "description": "填写具体行为，而不是抽象风格。可参考你熟悉或反感的商业笔记软件。",
      "type": "fill_blanks",
      "required": true,
      "blanks": [
        {
          "id": "launch_behavior",
          "label": "启动后看到什么",
          "placeholder": "例如直接恢复上次文档和视角，或进入极简文档列表",
          "required": true,
          "multiline": true,
          "max_length": 300
        },
        {
          "id": "toolbar_layout",
          "label": "工具栏位置与形态",
          "placeholder": "例如顶部固定、左侧竖栏、可拖动悬浮栏、自动隐藏",
          "required": true,
          "multiline": true,
          "max_length": 300
        },
        {
          "id": "navigation_gestures",
          "label": "平移、缩放和翻页手势",
          "placeholder": "例如单指平移、双指缩放、分页模式纵向连续滚动",
          "required": true,
          "multiline": true,
          "max_length": 400
        },
        {
          "id": "tool_switching",
          "label": "工具切换方式",
          "placeholder": "例如点击预设、侧键临时橡皮、长按弹出参数",
          "required": true,
          "multiline": true,
          "max_length": 400
        },
        {
          "id": "reference_apps",
          "label": "最想模仿和最想避免的软件体验",
          "placeholder": "例如喜欢 Samsung Notes 的跟手性，反感某软件工具栏层级过深",
          "required": false,
          "multiline": true,
          "max_length": 700
        }
      ]
    },
    {
      "id": "persistence_policy",
      "header": "数据策略",
      "question": "第一版采用哪种保存与恢复标准？",
      "description": "你此前说明存储不是重点，但最低数据可靠性仍会影响命令系统与文件结构。",
      "type": "single_select",
      "required": true,
      "options": [
        {
          "label": "单文件快照，定时完整保存",
          "value": "snapshot_only",
          "description": "实现最简单，但大型文档保存可能暂停，崩溃时可能丢失最近修改。"
        },
        {
          "label": "操作日志加周期快照",
          "value": "journal_plus_snapshot",
          "description": "每个完成命令追加日志，后台生成快照；兼顾性能与恢复能力。",
          "recommended": true
        },
        {
          "label": "嵌入式数据库事务",
          "value": "database_transactions",
          "description": "元素和命令分表存储，恢复可靠，但格式和迁移更复杂。"
        },
        {
          "label": "内存优先，退出时保存",
          "value": "save_on_exit",
          "description": "开发原型最轻量，但不适合尽早用于真实笔记。"
        }
      ],
      "allow_other": true
    },
    {
      "id": "development_philosophy",
      "header": "工程取舍",
      "question": "请填写你希望计划遵守的工程原则。",
      "description": "这些内容会被写入需求冻结区，用于防止后续加入功能时逐渐偏离你的原始目标。",
      "type": "fill_blanks",
      "required": true,
      "blanks": [
        {
          "id": "acceptable_prototype",
          "label": "最早可接受的可用原型",
          "placeholder": "例如只有无限画布、单支笔、缩放和平移，但必须极其流畅",
          "required": true,
          "multiline": true,
          "max_length": 500
        },
        {
          "id": "performance_vs_speed",
          "label": "性能与开发速度冲突时如何选择",
          "placeholder": "例如宁愿延期功能，也不接受已知线性退化路径",
          "required": true,
          "multiline": true,
          "max_length": 400
        },
        {
          "id": "rust_boundary",
          "label": "Rust 应承担到什么程度",
          "placeholder": "例如仅文档与空间索引，或连稳定渲染、几何算法也放入 Rust",
          "required": false,
          "multiline": true,
          "max_length": 500
        },
        {
          "id": "upstream_reuse",
          "label": "如何看待复制或移植开源实现",
          "placeholder": "例如允许直接移植成熟算法，但必须重构到清晰模块边界",
          "required": false,
          "multiline": true,
          "max_length": 500
        },
        {
          "id": "explicit_non_goals",
          "label": "第一版明确不允许加入的内容",
          "placeholder": "例如同步、AI、PDF、录音、协作、跨平台、动态插件",
          "required": true,
          "multiline": true,
          "max_length": 700
        },
        {
          "id": "commercial_software_frustrations",
          "label": "促使你开发本项目的具体痛点",
          "placeholder": "请写具体操作、缺失功能或长期未修复的问题，便于后续校验项目是否真正解决了动机",
          "required": false,
          "multiline": true,
          "max_length": 1000
        }
      ]
    }
  ]
}
```

</details>

# 附录 D：原始 Grill 第二轮回答

<details>
<summary>展开原始 JSON</summary>

```json
{
  "protocol": "chatgpt-grill-response/v1",
  "in_reply_to": "note-dev-requirements-02",
  "answers": [
    {
      "question_id": "foundation_strategy",
      "question": "你接受哪种项目起步方式？",
      "type": "single_select",
      "values": [
        "butterfly_mainline"
      ],
      "labels": [
        "以 Butterfly 为主仓库逐步重构"
      ]
    },
    {
      "question_id": "writing_tools",
      "question": "第一版必须具备哪些笔与输入行为？",
      "type": "multi_select",
      "values": [
        "pressure_pen",
        "stroke_smoothing",
        "barrel_button_eraser",
        "finger_navigation_only"
      ],
      "labels": [
        "单一压力钢笔",
        "笔迹稳定或平滑强度可调",
        "侧键临时切换橡皮擦",
        "手指只负责平移和缩放"
      ]
    },
    {
      "question_id": "hybrid_document_semantics",
      "question": "分页与无限画布应如何共存？",
      "type": "single_select",
      "values": [
        "mode_per_document"
      ],
      "labels": [
        "每个文档创建时二选一"
      ]
    },
    {
      "question_id": "editing_semantics",
      "question": "第一版必须支持哪些编辑语义？",
      "type": "multi_select",
      "values": [
        "stroke_eraser",
        "partial_eraser",
        "freeform_lasso",
        "selection_translate",
        "stroke_level_undo"
      ],
      "labels": [
        "整笔画橡皮擦",
        "局部像素式橡皮擦",
        "自由套索选择",
        "选区移动",
        "按一次落笔作为一个撤销单位"
      ],
      "other": "其余选项也逐步实现，只是本轮不实现"
    },
    {
      "question_id": "performance_failure_ranking",
      "question": "请排序最不可接受的性能问题。",
      "type": "ranking",
      "ranking": [
        {
          "rank": 1,
          "value": "visible_ink_lag",
          "label": "墨迹明显落后笔尖"
        },
        {
          "rank": 2,
          "value": "sample_loss",
          "label": "快速书写时丢采样点或笔画变形"
        },
        {
          "rank": 3,
          "value": "degrades_with_strokes",
          "label": "写满一页后延迟持续增加"
        },
        {
          "rank": 4,
          "value": "viewport_jank",
          "label": "缩放和平移掉帧"
        },
        {
          "rank": 5,
          "value": "post_edit_degradation",
          "label": "橡皮擦或套索后持续卡顿"
        },
        {
          "rank": 6,
          "value": "undo_pause",
          "label": "撤销或重做出现长暂停"
        }
      ],
      "unranked_values": [
        "autosave_jank",
        "slow_open",
        "memory_growth"
      ]
    },
    {
      "question_id": "interaction_workflow",
      "question": "请描述你希望的软件操作方式。",
      "type": "fill_blanks",
      "fields": [
        {
          "id": "launch_behavior",
          "label": "启动后看到什么",
          "value": "直接恢复"
        },
        {
          "id": "toolbar_layout",
          "label": "工具栏位置与形态",
          "value": "参考成熟商业产品的思路（仅参考思路）"
        },
        {
          "id": "navigation_gestures",
          "label": "平移、缩放和翻页手势",
          "value": "参考成熟商业产品的思路（仅参考思路）"
        },
        {
          "id": "tool_switching",
          "label": "工具切换方式",
          "value": "参考成熟商业产品的思路（仅参考思路）"
        },
        {
          "id": "reference_apps",
          "label": "最想模仿和最想避免的软件体验",
          "value": "Notein"
        }
      ]
    },
    {
      "question_id": "persistence_policy",
      "question": "第一版采用哪种保存与恢复标准？",
      "type": "single_select",
      "values": [
        "database_transactions"
      ],
      "labels": [
        "嵌入式数据库事务"
      ]
    },
    {
      "question_id": "development_philosophy",
      "question": "请填写你希望计划遵守的工程原则。",
      "type": "fill_blanks",
      "fields": [
        {
          "id": "acceptable_prototype",
          "label": "最早可接受的可用原型",
          "value": "只有无限画布，单只笔，基础的写和擦操作"
        },
        {
          "id": "performance_vs_speed",
          "label": "性能与开发速度冲突时如何选择",
          "value": "性能优先"
        },
        {
          "id": "rust_boundary",
          "label": "Rust 应承担到什么程度",
          "value": "Rust成为主要后端承担"
        },
        {
          "id": "upstream_reuse",
          "label": "如何看待复制或移植开源实现",
          "value": "以butterfly为例：先fork完整代码，然后保留功能的情况下重构前后端，验证软件行为不变，然后替换后端"
        },
        {
          "id": "explicit_non_goals",
          "label": "第一版明确不允许加入的内容",
          "value": "无"
        },
        {
          "id": "commercial_software_frustrations",
          "label": "促使你开发本项目的具体痛点",
          "value": "Notein虽然功能齐全，但是长期使用非常卡顿。我想在保留我常用功能的情况下优化性能"
        }
      ]
    }
  ]
}
```

</details>

# 附录 E：来源

完整来源、固定源码路径与官方文档见 `SOURCE_LEDGER_V1.md`。
