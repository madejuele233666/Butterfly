# 稳定 Trace section 名称

- stylus.dispatch
- stylus.history.decode
- stroke.foreground.update
- stroke.commit
- backend.apply_command
- rust.apply_command
- sqlite.begin
- sqlite.commit
- viewport.query
- viewport.bake
- selection.raycast
- eraser.split
- history.undo
- history.redo

重命名 trace section 需要 ADR，因为它会破坏历史可比性。
