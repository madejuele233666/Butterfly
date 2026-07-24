# SQLite 维护

- 默认不在书写手势中 checkpoint/VACUUM；
- 先观察默认 auto-checkpoint，再决定 idle checkpoint；
- 每次命令事务保持短小；
- writer 连接只归 Rust actor；
- busy_timeout 只处理外部极短竞争，不掩盖内部多 writer；
- quick_check 可在显式维护或异常启动时运行；
- full integrity_check 更低频；
- VACUUM/备份安排在文档关闭或明确维护时。
