import 'dart:async';
import 'dart:developer';

import 'm1_probe.dart';

abstract final class M1TraceName {
  static const stylusDispatch = 'stylus.dispatch';
  static const stylusHistoryDecode = 'stylus.history.decode';
  static const strokeForegroundUpdate = 'stroke.foreground.update';
  static const strokeCommit = 'stroke.commit';
  static const backendApplyCommand = 'backend.apply_command';
  static const rustApplyCommand = 'rust.apply_command';
  static const sqliteBegin = 'sqlite.begin';
  static const sqliteCommit = 'sqlite.commit';
  static const documentSave = 'document.save';
  static const viewportQuery = 'viewport.query';
  static const viewportBake = 'viewport.bake';
  static const selectionRaycast = 'selection.raycast';
  static const eraserSplit = 'eraser.split';
  static const historyUndo = 'history.undo';
  static const historyRedo = 'history.redo';
}

abstract final class M1Trace {
  static T sync<T>(String name, T Function() body) {
    if (!m1ProbeEnabled) return body();
    Timeline.startSync(name);
    try {
      return body();
    } finally {
      Timeline.finishSync();
    }
  }

  static Future<T> async<T>(String name, FutureOr<T> Function() body) async {
    if (!m1ProbeEnabled) return await body();
    final task = TimelineTask()..start(name);
    try {
      return await body();
    } finally {
      task.finish();
    }
  }
}
