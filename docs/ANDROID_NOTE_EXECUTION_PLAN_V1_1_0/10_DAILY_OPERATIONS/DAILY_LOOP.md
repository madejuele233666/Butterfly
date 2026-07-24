# 日常开发循环

## UI/普通逻辑

AVD + devDebug + hot reload。提交前跑单元和 smoke test。

## 输入/手势

OPPO 真机 devDebug。使用 USB 或 Wi-Fi ADB；涉及样本/侧键时开启探针。

## 性能

OPPO 真机 devProfile。关闭镜像、录屏和高频日志；填写 run record；导出 trace。

## Rust/SQLite

PC 先跑单元、属性和 fixture 测试；AVD 跑 migration/fault；OPPO 跑 I/O 与 frame 联合测试。

## 日用

personalRelease，单独 applicationId 和数据库目录。开发版不得直接打开唯一真实笔记，除非先备份。
