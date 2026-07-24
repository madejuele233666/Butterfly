# SQLite 配置裁决门

比较：

- WAL + FULL；
- WAL + NORMAL；
- PERSIST + FULL。

同一 OPPO 设备、同一命令 trace、同一 payload 和同一 durability 说明。记录 commit P50/P95/P99、checkpoint、帧时间、文件增长和 force-stop 恢复。

配置选择只裁决 storage owner。活动墨迹、stable renderer 或几何开销不得通过修改 SQLite 配置掩盖；阈值和允许的事务丢失语义必须在结果出现前冻结。

选择标准不是平均吞吐，而是：

1. 书写期间 P99 不制造 jank；
2. 应用崩溃后数据库不损坏；
3. 可接受的最近事务丢失语义被明确写入；
4. checkpoint/maintenance 可调度到 idle；
5. 备份和恢复经过演练。
