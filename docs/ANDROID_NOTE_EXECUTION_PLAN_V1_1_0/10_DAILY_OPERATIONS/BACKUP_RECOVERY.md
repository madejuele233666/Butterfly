# 备份与恢复操作

1. 日用版每次 schema migration 前创建一致备份。
2. 活跃 SQLite 不只复制主 `.notedb` 文件；使用 Online Backup API 或 `VACUUM INTO`。
3. 每月执行一次从备份恢复到新路径的演练。
4. 保留最近多个不可变备份，不覆盖唯一上一版。
5. 恢复后执行 quick_check、foreign_key_check 和应用语义检查。
6. Debug 数据与 personalRelease 数据目录分离。
