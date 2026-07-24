# 调研来源台账

版本：1.1.0  
日期：2026-07-24  
用途：记录主计划中的外部事实来源。实施时应优先重新核对官方文档与固定版本源码。

1.1.0 更新：保留 1.0.1 的 SQLite 决策；增加 Android Studio、AVD、真机无线联调、profileable、System Trace、Simpleperf、Device Explorer、Rootless GLES 和 Flutter 构建模式的官方依据。

## A. Butterfly 固定基线与源码

1. Butterfly 2.5.3 stable release, 2026-06-08  
   https://www.linwood.dev/butterfly/2.5.3/
2. Butterfly supported versions and branch policy  
   https://butterfly.linwood.dev/community/versions/
3. Butterfly 2.6 changelog；2.6.0-beta.2 明确包含 `Refactor whole state management structure`  
   https://butterfly.linwood.dev/changelog/
4. Butterfly tag `v2.5.3`, `app/pubspec.yaml`；Flutter 3.44.1  
   https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/pubspec.yaml
5. 稳定内容 Baking、前景层与可见未烘焙元素  
   https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/view_painter.dart
6. CameraViewport baked/unbaked/visible 模型  
   https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/models/viewport.dart
7. PenHandler 输入、压力、前景刷新、提交与延迟 Baking  
   https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/handlers/pen.dart
8. PenRenderer / perfect_freehand / 路径缓存  
   https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/renderers/elements/pen.dart
9. 局部橡皮擦当前按原始点删除并切段  
   https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/handlers/eraser.dart
10. 整笔画橡皮擦当前的 raycast、临时隐藏、抬笔提交模式  
    https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/handlers/path_eraser.dart
11. SelectHandler 当前将选择语义与 Renderer 对象、变换逻辑绑定  
    https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/handlers/select.dart
12. DocumentBloc 当前继承 ReplayBloc，并同时连接文档、CurrentIndex、渲染与文件系统  
    https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/app/lib/bloc/document_bloc.dart
13. PathPoint 当前只保存 x/y/pressure  
    https://github.com/LinwoodDev/Butterfly/blob/v2.5.3/api/lib/src/models/point.dart
14. 性能回归案例：eraser/lasso/undo 后持续卡顿直到重新 bake  
    https://github.com/LinwoodDev/Butterfly/issues/827
15. 大型单页性能问题  
    https://github.com/LinwoodDev/Butterfly/issues/667

## B. Android / Jetpack Ink / Flutter

16. Jetpack Ink release notes；stable 1.0.0，1.1.0-alpha05 的 partial-stroke eraser 仍缺切口抗锯齿和结果序列化  
    https://developer.android.com/jetpack/androidx/releases/ink
17. InProgressStrokesView；支持 MotionEvent、预测事件、`eagerInit()`、`requestUnbufferedDispatch` 建议  
    https://developer.android.com/reference/androidx/ink/authoring/InProgressStrokesView
18. MotionEvent 历史采样、压力和批次  
    https://developer.android.com/reference/android/view/MotionEvent
19. MotionEventPredictor  
    https://developer.android.com/reference/androidx/input/motionprediction/MotionEventPredictor
20. Android stylus advanced features  
    https://developer.android.com/develop/ui/views/touch-and-input/stylus-input/advanced-stylus-features
21. Android stylus button constants：BUTTON_STYLUS_PRIMARY / SECONDARY  
    https://developer.android.com/reference/android/view/MotionEvent
22. Flutter Android Platform Views 与 HCPP；Flutter 3.44+、API 34+、Vulkan 要求及透明叠层限制  
    https://docs.flutter.dev/platform-integration/android/platform-views

## C. Rust 桥接、数据库与空间索引

23. flutter_rust_bridge 2.12.0  
    https://docs.rs/flutter_rust_bridge/2.12.0/flutter_rust_bridge/
24. flutter_rust_bridge Dart docs；async、opaque types、streams、zero-copy arrays  
    https://pub.dev/documentation/flutter_rust_bridge/latest/
25. rusqlite 0.40.1；`bundled` 适合自行控制数据库的应用；调研时 bundled SQLite 为 3.53.2  
    https://docs.rs/crate/rusqlite/latest
26. SQLite 适用边界：设备本地、低 writer 并发、单文件数据  
    https://www.sqlite.org/whentouse.html
27. SQLite WAL；reader/writer 并行但同一时刻仅一个 writer；默认约 1000 页 auto-checkpoint；checkpoint starvation  
    https://www.sqlite.org/wal.html
28. `PRAGMA synchronous`：WAL + NORMAL 的一致性与耐久取舍；WAL + FULL 每次提交额外同步；EXTRA 在 WAL 中等同 FULL  
    https://www.sqlite.org/pragma.html#pragma_synchronous
29. `PRAGMA journal_mode`：DELETE/TRUNCATE/PERSIST/WAL/OFF 的语义与持久性  
    https://www.sqlite.org/pragma.html#pragma_journal_mode
30. `WITHOUT ROWID` 的适用范围；大型字符串/BLOB 行通常更适合普通 rowid table，且 WITHOUT ROWID 不支持 incremental BLOB I/O  
    https://www.sqlite.org/withoutrowid.html
31. SQLite Online Backup API；活跃数据库的一致快照与增量复制  
    https://www.sqlite.org/backup.html
32. `VACUUM INTO`；生成压缩后的 live database 备份副本  
    https://www.sqlite.org/lang_vacuum.html#vacuum_with_an_into_clause
33. `PRAGMA integrity_check`、`quick_check` 与 `foreign_key_check` 的范围差异  
    https://www.sqlite.org/pragma.html#pragma_integrity_check
34. SQLite isolation / snapshot isolation  
    https://www.sqlite.org/isolation.html
35. SQLite R*Tree；矩形范围查询与默认 f32 坐标舍入  
    https://www.sqlite.org/rtree.html
36. rstar RTree 0.13；`locate_in_envelope_intersecting`  
    https://docs.rs/rstar/0.13.0/rstar/struct.RTree.html

## D. 参考产品与目标硬件

37. Notein Help Center  
    https://help.notein.ai/
38. Notein Pen Box and Toolbar  
    https://support.note-in.com/ae1b/84e8
39. Notein Multi-Function Eraser  
    https://support.note-in.com/ae1b/8ffd
40. Notein handwriting pen shortcuts；OPPO 双击映射  
    https://support.note-in.com/ae1b/4d64
41. Notein common gestures  
    https://support.note-in.com/ae1b/b9d8
42. OPPO 官方平板页；OPPO Pencil 2 列为“快捷按键”，但公开页面未证明应用能得到按下/松开语义  
    https://www.oppo.com/cn/tablets/
43. OPPO Pencil（上一代）官方能力：240Hz、4096 压感、双击、局部刷新 SDK；仅作为能力参考，不能直接等同于 Pencil 2 事件接口  
    https://www.oppo.com/cn/accessories/oppo-pencil/

## E. 性能测量

44. Android JankStats  
    https://developer.android.com/topic/performance/jankstats
45. Macrobenchmark FrameTimingMetric  
    https://developer.android.com/topic/performance/benchmarking/macrobenchmark-overview
46. Perfetto frame timeline  
    https://developer.android.com/topic/performance/vitals/render
47. Flutter `SchedulerBinding.addTimingsCallback` / FrameTiming  
    https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html

## F. 开发环境、真机联调与 Root 诊断

48. Android Studio：在硬件设备运行、USB 调试、Android 11+ Wi-Fi pairing、Device Mirroring  
    https://developer.android.com/studio/run/device
49. Android Virtual Device 创建与管理  
    https://developer.android.com/studio/run/managing-avds
50. Android Emulator 硬件加速；Windows 推荐 Windows Hypervisor Platform  
    https://developer.android.com/studio/run/emulator-acceleration
51. Flutter build modes：Debug 用于开发、Profile 用于性能、Release 用于发布/最终体验  
    https://docs.flutter.dev/testing/build-modes
52. Android `<profileable>`；debuggable 会产生显著性能退化，profileable 适合本地精确时序测量  
    https://developer.android.com/guide/topics/manifest/profileable-element
53. Android Studio Profiler：profileable 与 debuggable 的能力和成本差异  
    https://developer.android.com/studio/profile
54. Android Studio System Trace / trace inspection：线程、frame timeline、RSS  
    https://developer.android.com/studio/profile/inspect-traces
55. Simpleperf：Android NDK 自带 native CPU profiler  
    https://developer.android.com/ndk/guides/simpleperf
56. Device Explorer：普通硬件只可访问有限数据；Root 或 AOSP 模拟器可查看更多  
    https://developer.android.com/studio/debug/device-file-explorer
57. Rootless GLES layers：debuggable 应用可从自身目录/APK加载图形调试层，系统位置才要求 Root  
    https://developer.android.com/ndk/guides/rootless-debug-gles
58. MotionEvent 历史采样适合绘制轨迹，必须遍历 `getHistorySize()`  
    https://developer.android.com/develop/ui/views/touch-and-input/gestures/movement
59. Android 多指手势中的 pointer ID、ACTION_POINTER_DOWN/UP 与 ACTION_CANCEL  
    https://developer.android.com/develop/ui/views/touch-and-input/gestures/multi

