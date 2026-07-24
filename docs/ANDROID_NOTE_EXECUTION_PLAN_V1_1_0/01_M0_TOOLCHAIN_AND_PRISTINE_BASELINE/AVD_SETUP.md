# AVD 配置

1. Android Studio → Device Manager → Create Virtual Device。
2. 选择 Pixel Tablet 或相近 tablet profile。
3. 选择 API 36 AOSP x86_64 镜像。
4. 名称：`NoteDev_API36_Tablet`。
5. Graphics：Automatic/Hardware。
6. RAM：4–8 GB；Storage：16 GB。
7. 启动后运行：

```powershell
adb devices -l
$env:ANDROID_HOME + "\emulator\emulator.exe" -accel-check
```

AVD 只用于逻辑、迁移和自动化测试，不做笔迹延迟裁决。
