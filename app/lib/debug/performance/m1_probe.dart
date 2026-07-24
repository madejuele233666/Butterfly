import 'dart:async';
import 'dart:convert';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'm1_probe_export_stub.dart'
    if (dart.library.io) 'm1_probe_export_io.dart';
import 'ring_buffer.dart';

const m1ProbeEnabled = bool.fromEnvironment(
  'M1_PROBE_ENABLED',
  defaultValue: false,
);

class M1ProbeController extends ChangeNotifier {
  static final instance = M1ProbeController._();
  static const _channel = MethodChannel('dev.linwood.notea/m1_probe');
  static const _capacity = 32768;

  final RingBuffer<Map<String, Object?>> _flutterRecords = RingBuffer(
    _capacity,
  );
  bool _running = false;
  Map<String, Object?> _nativeStatus = const {};
  String? _lastExportPath;

  M1ProbeController._();

  bool get running => _running;
  String? get lastExportPath => _lastExportPath;
  Map<String, Object?> get nativeStatus => _nativeStatus;
  int get flutterRetained => _flutterRecords.length;
  int get flutterDropped => _flutterRecords.dropped;

  Future<void> start() async {
    if (!m1ProbeEnabled) return;
    _nativeStatus = _map(
      await _channel.invokeMethod<Object?>('start', {'capacity': _capacity}),
    );
    if (!_running) {
      WidgetsBinding.instance.addTimingsCallback(_captureFrames);
    }
    _running = true;
    notifyListeners();
  }

  Future<void> stop() async {
    if (!m1ProbeEnabled) return;
    _nativeStatus = _map(await _channel.invokeMethod<Object?>('stop'));
    if (_running) {
      WidgetsBinding.instance.removeTimingsCallback(_captureFrames);
    }
    _running = false;
    notifyListeners();
  }

  Future<void> reset() async {
    _flutterRecords.clear();
    _lastExportPath = null;
    if (m1ProbeEnabled) {
      _nativeStatus = _map(await _channel.invokeMethod<Object?>('reset'));
    }
    notifyListeners();
  }

  Future<void> refreshStatus() async {
    if (!m1ProbeEnabled) return;
    _nativeStatus = _map(await _channel.invokeMethod<Object?>('status'));
    notifyListeners();
  }

  void capturePointer(PointerEvent event) {
    if (!_running || !m1ProbeEnabled) return;
    _flutterRecords.add({
      'schema': 'notea.m1.pointer/v1',
      'sourceLayer': 'flutter',
      'eventType': event.runtimeType.toString(),
      'eventTimeNanos': event.timeStamp.inMicroseconds * 1000,
      'pointer': event.pointer,
      'device': event.device,
      'kind': event.kind.name,
      'buttons': event.buttons,
      'down': event.down,
      'synthesized': event.synthesized,
      'obscured': event.obscured,
      'position': {'x': event.position.dx, 'y': event.position.dy},
      'localPosition': {
        'x': event.localPosition.dx,
        'y': event.localPosition.dy,
      },
      'delta': {'x': event.delta.dx, 'y': event.delta.dy},
      'pressure': event.pressure,
      'pressureMin': event.pressureMin,
      'pressureMax': event.pressureMax,
      'distance': event.distance,
      'distanceMin': event.distanceMin,
      'distanceMax': event.distanceMax,
      'size': event.size,
      'radiusMajor': event.radiusMajor,
      'radiusMinor': event.radiusMinor,
      'orientation': event.orientation,
      'tilt': event.tilt,
    });
  }

  void _captureFrames(List<FrameTiming> timings) {
    if (!_running) return;
    for (final timing in timings) {
      _flutterRecords.add({
        'schema': 'notea.m1.frame/v1',
        'sourceLayer': 'flutter',
        'frameNumber': timing.frameNumber,
        'vsyncStartMicros': timing.timestampInMicroseconds(
          FramePhase.vsyncStart,
        ),
        'buildStartMicros': timing.timestampInMicroseconds(
          FramePhase.buildStart,
        ),
        'buildFinishMicros': timing.timestampInMicroseconds(
          FramePhase.buildFinish,
        ),
        'rasterStartMicros': timing.timestampInMicroseconds(
          FramePhase.rasterStart,
        ),
        'rasterFinishMicros': timing.timestampInMicroseconds(
          FramePhase.rasterFinish,
        ),
        'buildMicros': timing.buildDuration.inMicroseconds,
        'rasterMicros': timing.rasterDuration.inMicroseconds,
        'totalMicros': timing.totalSpan.inMicroseconds,
        'vsyncOverheadMicros': timing.vsyncOverhead.inMicroseconds,
      });
    }
  }

  Future<String> exportJsonl() async {
    if (!m1ProbeEnabled) {
      throw StateError('M1 probe was not enabled at build time');
    }
    if (_running) {
      await stop();
    } else {
      await refreshStatus();
    }
    final native = <String>[];
    var offset = 0;
    while (true) {
      final chunk = await _channel.invokeListMethod<String>('records', {
        'offset': offset,
        'limit': 1024,
      });
      if (chunk == null || chunk.isEmpty) break;
      native.addAll(chunk);
      offset += chunk.length;
      if (chunk.length < 1024) break;
    }
    final now = DateTime.now().toUtc();
    final sessionId = 'm1-${now.toIso8601String().replaceAll(':', '-')}';
    final header = jsonEncode({
      'schema': 'notea.m1.session/v1',
      'sessionId': sessionId,
      'exportedAt': now.toIso8601String(),
      'nativeStatus': _nativeStatus,
      'flutterStatus': {
        'capacity': _capacity,
        'retained': _flutterRecords.length,
        'captured': _flutterRecords.captured,
        'dropped': _flutterRecords.dropped,
      },
    });
    final contents = [
      header,
      ...native,
      ..._flutterRecords.records.map(jsonEncode),
      '',
    ].join('\n');
    _lastExportPath = await writeM1ProbeJsonl(contents, sessionId);
    notifyListeners();
    return _lastExportPath!;
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}

class M1ProbeBoundary extends StatelessWidget {
  final Widget child;

  const M1ProbeBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!m1ProbeEnabled) return child;
    final probe = M1ProbeController.instance;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: probe.capturePointer,
      onPointerMove: probe.capturePointer,
      onPointerUp: probe.capturePointer,
      onPointerHover: probe.capturePointer,
      onPointerCancel: probe.capturePointer,
      onPointerSignal: probe.capturePointer,
      onPointerPanZoomStart: probe.capturePointer,
      onPointerPanZoomUpdate: probe.capturePointer,
      onPointerPanZoomEnd: probe.capturePointer,
      child: child,
    );
  }
}
