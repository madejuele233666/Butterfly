import 'dart:convert';
import 'dart:typed_data';

import 'package:butterfly/debug/performance/m1_baseline_export_stub.dart'
    if (dart.library.io) 'm1_baseline_export_io.dart';
import 'package:butterfly/debug/performance/m1_fixture.dart';
import 'package:butterfly/debug/performance/m1_legacy_oracle.dart';
import 'package:butterfly/debug/performance/m1_probe.dart';
import 'package:butterfly/views/main.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class M1BaselinePage extends StatefulWidget {
  const M1BaselinePage({
    super.key,
    required this.fixture,
    this.runs = 3,
  });

  final M1FixtureId fixture;
  final int runs;

  @override
  State<M1BaselinePage> createState() => _M1BaselinePageState();
}

class _M1BaselinePageState extends State<M1BaselinePage> {
  late Future<Uint8List> _fixtureBytes;
  final List<Map<String, Object?>> _results = [];
  int _run = 1;
  bool _finishing = false;
  String? _exportPath;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fixtureBytes = compute(generateM1FixtureBytes, widget.fixture.label);
  }

  Future<void> _completed(M1LegacyReplayResult result) async {
    if (_finishing || !mounted) return;
    _results.add(result.toJson());
    if (_run < widget.runs) {
      setState(() => _run++);
      return;
    }
    setState(() => _finishing = true);
    try {
      final now = DateTime.now().toUtc();
      final sessionId = 'm1-baseline-${widget.fixture.label.toLowerCase()}-'
          '${now.toIso8601String().replaceAll(':', '-')}';
      final contents = const JsonEncoder.withIndent('  ').convert({
        'schema': 'notea.m1.baseline-session/v1',
        'fixture': widget.fixture.label,
        'requestedRuns': widget.runs,
        'completedRuns': _results.length,
        'exportedAt': now.toIso8601String(),
        'replayVersion': m1LegacyReplayVersion,
        'normalizationVersion': m1NormalizationVersion,
        'decisionRulesVersion': m1DecisionRulesVersion,
        'runs': _results,
      });
      final path = await writeM1BaselineJson(contents, sessionId);
      if (mounted) setState(() => _exportPath = path);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _failed(Object error) {
    if (!mounted) return;
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    if (!m1ProbeEnabled) {
      return const Scaffold(
        body: Center(child: Text('M1 baseline 未在此构建中启用。')),
      );
    }
    if (_error != null || _exportPath != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('M1 → M2 基线结果')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            _error != null
                ? '失败：$_error'
                : '已完成 ${_results.length}/${widget.runs} 轮。\n'
                      'Oracle：$_exportPath\n\n'
                      '每轮 Pointer/Frame JSONL 位于应用 m1-probe 目录。',
          ),
        ),
      );
    }
    if (_finishing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return FutureBuilder<Uint8List>(
      future: _fixtureBytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('${snapshot.error}')));
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ProjectPage(
          key: ValueKey('${widget.fixture.label}-$_run'),
          data: NoteData.fromData(bytes),
          m1BaselineRun: M1BaselineRunConfig(
            fixture: widget.fixture,
            run: _run,
          ),
          onM1BaselineCompleted: _completed,
          onM1BaselineFailed: _failed,
        );
      },
    );
  }
}
