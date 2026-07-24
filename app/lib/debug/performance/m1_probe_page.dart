import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'm1_probe.dart';

class M1ProbePage extends StatefulWidget {
  const M1ProbePage({super.key});

  @override
  State<M1ProbePage> createState() => _M1ProbePageState();
}

class _M1ProbePageState extends State<M1ProbePage> {
  final probe = M1ProbeController.instance;
  bool busy = false;

  static const actions = [
    '1. 悬停',
    '2. 普通落笔',
    '3. 轻压到重压',
    '4. 快速直线与曲线',
    '5. 慢速直线',
    '6. 不同倾斜角',
    '7. 悬停时侧键按下/松开',
    '8. 落笔时侧键按下/松开',
    '9. 双击/快捷键单击/长按',
    '10. 手掌先接触后落笔',
    '11. 笔先落下后放手掌',
    '12. 双指缩放期间笔悬停',
  ];

  @override
  void initState() {
    super.initState();
    probe.addListener(_changed);
    probe.refreshStatus();
  }

  @override
  void dispose() {
    probe.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!m1ProbeEnabled) {
      return const Scaffold(
        body: Center(
          child: Text('M1 probe 未在此构建中启用。'),
        ),
      );
    }
    final status = probe.nativeStatus;
    return Scaffold(
      appBar: AppBar(title: const Text('M1 输入与性能探针')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            probe.running ? '采集中（仅内存，不逐事件写盘）' : '已停止',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Android retained=${status['retained'] ?? 0}, '
            'dropped=${status['dropped'] ?? 0}\n'
            'Flutter retained=${probe.flutterRetained}, '
            'dropped=${probe.flutterDropped}\n'
            'Refresh=${status['refreshRateHz'] ?? 'unknown'} Hz\n'
            'Device=${status['manufacturer'] ?? 'unknown'} '
            '${status['model'] ?? ''}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy || probe.running
                    ? null
                    : () => _run(probe.start),
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('开始'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy || !probe.running
                    ? null
                    : () => _run(probe.stop),
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _run(probe.reset),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('清空内存'),
              ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => _run(() async {
                        final path = await probe.exportJsonl();
                        await Clipboard.setData(ClipboardData(text: path));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('JSONL 路径已复制')),
                          );
                        }
                      }),
                icon: const Icon(Icons.save_alt),
                label: const Text('一次性导出 JSONL'),
              ),
            ],
          ),
          if (probe.lastExportPath != null) ...[
            const SizedBox(height: 12),
            SelectableText('最近导出：${probe.lastExportPath}'),
          ],
          const Divider(height: 32),
          Text('真机动作矩阵', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...actions.map((action) => Text(action)),
          const SizedBox(height: 12),
          const Text(
            '60 Hz 与 120 Hz 必须分别采集。Debug 只用于确认事件能力；'
            '帧时间裁决必须使用 devProfile，并关闭镜像、录屏和高频 Logcat。',
          ),
        ],
      ),
    );
  }
}
