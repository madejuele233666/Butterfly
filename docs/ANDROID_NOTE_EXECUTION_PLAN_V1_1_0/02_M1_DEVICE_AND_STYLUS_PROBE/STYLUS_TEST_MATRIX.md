# OPPO Pencil 2 测试动作

每项重复 5 次，先清空 ring buffer，再开始采集。

| ID | 动作 | 重点字段 |
|---|---|---|
| S01 | 悬停圆周移动 | distance, hover action, toolType |
| S02 | 轻压直线 | pressure min/max |
| S03 | 逐渐加压直线 | pressure monotonicity |
| S04 | 快速直线 | historySize, sample intervals |
| S05 | 快速小字 | sample loss, pointer continuity |
| S06 | 慢速直线 | jitter, duplicate points |
| S07 | 不同倾角 | tilt, orientation |
| S08 | 悬停侧键按/松 | buttonState, KeyEvent |
| S09 | 落笔侧键按/松 | actionButton, toolType |
| S10 | 双击 | KeyEvent/GenericMotion/系统动作 |
| S11 | 手掌先触屏再落笔 | pointer routing, CANCEL |
| S12 | 笔先落下再放手掌 | canceled flag, stroke termination |
