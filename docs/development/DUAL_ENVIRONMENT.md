# WSL 主开发与 Windows 测试镜像

## 责任边界

| 环境 | 工作区 | 责任 |
|---|---|---|
| WSL | `/home/madejuele/projects/Notea` | 主力开发、代码修改、提交、合并与基线维护 |
| Windows | `D:\files\Notea_Mirror\workspace` | Android/Windows 工具链、AVD、USB 真机、构建与测试 |
| Git 中继 | `D:\files\Notea_Mirror\git\Notea.git` | 仅保存 Git 对象和 refs，不是可执行工作区 |
| Windows 证据区 | `D:\files\Notea_Mirror\evidence` | 大型 APK、截图、日志和其他不进入 Git 的原始证据 |

SDK、Gradle 缓存、Flutter 缓存、Rust `target`、密钥和本机临时输出不在两侧复制。需要进入项目历史的工具链锁、摘要和小型证据应在 `artifacts/` 中明确添加并提交。

## 同步协议

同步只传递已经提交的 Git 对象。两个脚本都会检查：

1. `baseline/v2.5.3-pristine` 仍指向 `a10a9787fd4fdc51c9426ead83ff063136015fb2`；
2. 当前工作树干净；
3. 拉取只能 fast-forward；
4. 分叉、未提交修改或基线漂移都会显式失败。

脚本不会自动提交、自动合并分叉、复制整个目录或删除环境文件。

### WSL

```bash
./scripts/sync-code.sh sync
```

也可显式执行 `pull` 或 `push`：

```bash
./scripts/sync-code.sh push work/v1-main
./scripts/sync-code.sh pull work/v1-main
```

### Windows PowerShell

```powershell
Set-Location D:\files\Notea_Mirror\workspace
.\scripts\sync-code.ps1 sync
```

Windows 通常只需 `pull` 后执行测试；只有测试记录或 Windows 侧修复已经提交时才执行 `push`。

## 冲突处理

脚本遇到非 fast-forward 会停止。回到变更的责任环境人工检查提交图、解决冲突并完成普通 Git 合并或 rebase；禁止通过复制目录覆盖另一侧工作区。

