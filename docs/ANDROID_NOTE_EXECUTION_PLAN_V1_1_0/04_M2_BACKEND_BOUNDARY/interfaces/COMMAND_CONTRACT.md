# Command / Delta 契约

## Command 必须包含

- command_id
- expected_revision
- document/space ID
- 完整、已验证的业务输入
- 手势级事务边界

## Delta 必须包含

- before_revision / after_revision
- created IDs
- updated IDs + new headers/payload refs
- removed IDs
- dirty world bounds
- history cursor
- 可选 diagnostic timing

## 禁止

- Command 持有 BuildContext、Renderer、Bloc；
- Delta 返回整份文档；
- UI 用 fallback 猜测后端是否已提交；
- revision 冲突时静默覆盖。
