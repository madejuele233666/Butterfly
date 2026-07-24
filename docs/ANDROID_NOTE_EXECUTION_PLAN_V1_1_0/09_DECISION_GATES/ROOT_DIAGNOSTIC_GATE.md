# Root 诊断门

## 原则

Root 只用于读取更深层事实，不成为 V1 运行依赖，也不用于“让功能先工作起来”。

## 进入条件

- MotionEvent、GenericMotionEvent、KeyEvent 均看不到侧键；或
- 输入存在不可解释丢失；或
- 普通 profileable 工具无法定位内核/厂商层问题。

## Root 前

- 保存原厂 build fingerprint；
- 保存无 Root 输入报告；
- 保存无 Root Profile/Release trace；
- 建立恢复方案。

## 只读第一轮

```powershell
adb shell su -c "cat /proc/bus/input/devices"
adb shell su -c "getevent -lp"
# 确认 eventX 后，在短时间内运行：
adb shell su -c "getevent -lt /dev/input/eventX"
```

不要在第一轮执行 setenforce、disable-verity、刷模块或修改输入映射。

## 结论分类

1. Linux 层也无事件：硬件/固件不暴露；
2. Linux 层有事件，普通 API 无事件：厂商系统消费；
3. 普通 API 有事件但 Flutter 无：桥接/框架问题；
4. Root bridge 才能用：必须单独评估是否接受 Root-only 私人功能。
