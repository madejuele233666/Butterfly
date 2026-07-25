import 'dart:async';

import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/debug/performance/m1_legacy_oracle.dart';
import 'package:butterfly/debug/performance/m1_probe.dart';
import 'package:flutter/material.dart';

class M1BaselinePanel extends StatefulWidget {
  const M1BaselinePanel({
    super.key,
    required this.bloc,
    required this.config,
    required this.onCompleted,
    required this.onFailed,
  });

  final DocumentBloc bloc;
  final M1BaselineRunConfig config;
  final ValueChanged<M1LegacyReplayResult> onCompleted;
  final ValueChanged<Object> onFailed;

  @override
  State<M1BaselinePanel> createState() => _M1BaselinePanelState();
}

class _M1BaselinePanelState extends State<M1BaselinePanel> {
  bool _started = false;
  String _status = '等待真实 document canvas 稳定';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_started || !mounted) return;
    _started = true;
    final probe = M1ProbeController.instance;
    try {
      setState(() => _status = '预热画布');
      await Future<void>.delayed(const Duration(seconds: 1));
      await widget.bloc.bake(reset: true);
      await probe.reset();
      await probe.start();
      probe.captureMarker('baseline.run.start', {
        'fixture': widget.config.fixture.label,
        'run': widget.config.run,
        'replayVersion': m1LegacyReplayVersion,
      });
      if (mounted) setState(() => _status = '执行确定性 Legacy replay');
      final result = await M1LegacyOracleRunner().run(
        widget.bloc,
        M1LegacyReplayRequest(
          fixture: widget.config.fixture,
          run: widget.config.run,
        ),
      );
      probe.captureMarker('baseline.run.finish', {
        'fixture': widget.config.fixture.label,
        'run': widget.config.run,
      });
      await probe.stop();
      await probe.exportJsonl();
      if (!mounted) return;
      setState(() => _status = '完成；重建干净 fixture');
      widget.onCompleted(result);
    } catch (error) {
      if (probe.running) {
        unawaited(probe.stop());
      }
      if (mounted) setState(() => _status = '失败：$error');
      widget.onFailed(error);
    }
  }

  @override
  Widget build(BuildContext context) => Positioned(
    top: 12,
    right: 12,
    child: IgnorePointer(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${widget.config.fixture.label} '
            'run ${widget.config.run}: $_status',
          ),
        ),
      ),
    ),
  );
}
