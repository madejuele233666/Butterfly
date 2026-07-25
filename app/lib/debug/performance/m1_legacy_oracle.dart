import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/debug/performance/m1_fixture.dart';
import 'package:butterfly/debug/performance/trace.dart';
import 'package:butterfly_api/butterfly_api.dart';

const m1LegacyOracleSchema = 'notea.m1.legacy-oracle/v1';
const m1LegacyReplayVersion = 'legacy-elements-v1';
const m1NormalizationVersion = 'element-json-f64-1e-6-v1';
const m1DecisionRulesVersion = 'm1-m2-gate-2026-07-25-v1';

final class M1BaselineRunConfig {
  const M1BaselineRunConfig({required this.fixture, required this.run});

  final M1FixtureId fixture;
  final int run;
}

final class M1LegacyReplayRequest {
  const M1LegacyReplayRequest({
    required this.fixture,
    required this.run,
    this.exerciseRenderingOwners = true,
  });

  final M1FixtureId fixture;
  final int run;
  final bool exerciseRenderingOwners;
}

final class M1LegacyReplayResult {
  const M1LegacyReplayResult({
    required this.fixture,
    required this.run,
    required this.startedAt,
    required this.finishedAt,
    required this.initialFixtureHash,
    required this.steps,
  });

  final String fixture;
  final int run;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String initialFixtureHash;
  final List<Map<String, Object?>> steps;

  Map<String, Object?> toJson() => {
    'schema': m1LegacyOracleSchema,
    'replayVersion': m1LegacyReplayVersion,
    'normalizationVersion': m1NormalizationVersion,
    'decisionRulesVersion': m1DecisionRulesVersion,
    'fixture': fixture,
    'run': run,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    'initialFixtureHash': initialFixtureHash,
    'revisionSemantics': {
      'kind': 'legacyReplaySequence',
      'productionRevisionAvailable': false,
      'description':
          'Monotonic replay observation index; not a production document revision.',
    },
    'historySemantics': {
      'kind': 'observedReplayPosition',
      'productionCursorAvailable': false,
      'description':
          'Position maintained from observed Legacy state emissions and checked against canUndo/canRedo.',
    },
    'steps': steps,
  };
}

final class _NormalizedSnapshot {
  const _NormalizedSnapshot({
    required this.hash,
    required this.elementCount,
    required this.layerOrder,
    required this.elements,
  });

  final String hash;
  final int elementCount;
  final Map<String, List<String>> layerOrder;
  final Map<String, String> elements;
}

final class M1LegacyOracleRunner {
  int _sequenceRevision = 0;
  int _historyPosition = 0;
  int _historyHead = 0;

  Future<M1LegacyReplayResult> run(
    DocumentBloc bloc,
    M1LegacyReplayRequest request,
  ) async {
    final initialState = _loaded(bloc);
    if (bloc.canUndo || bloc.canRedo) {
      throw StateError('M1 replay requires a fresh Legacy history stack');
    }
    final startedAt = DateTime.now().toUtc();
    var previous = _snapshot(initialState);
    final initialFixtureHash = previous.hash;
    final steps = <Map<String, Object?>>[
      _record('initial', previous, previous, bloc),
    ];

    final create = _oracleStroke('m1-oracle-create', 1000000);
    previous = await _applyAndRecord(
      bloc,
      previous,
      'create-stroke',
      ElementsCreated([create]),
      steps,
      expectedPresent: const {'m1-oracle-create'},
    );

    previous = await _applyAndRecord(
      bloc,
      previous,
      'erase-strokes',
      const ElementsRemoved(['m1-oracle-create']),
      steps,
      expectedAbsent: const {'m1-oracle-create'},
    );

    final partialSource = _oracleStroke('m1-oracle-partial-source', 1000010);
    previous = await _applyAndRecord(
      bloc,
      previous,
      'partial-erase-setup',
      ElementsCreated([partialSource]),
      steps,
      expectedPresent: const {'m1-oracle-partial-source'},
    );
    final partialLeft = partialSource.copyWith(
      id: 'm1-oracle-partial-left',
      points: partialSource.points.take(3).toList(growable: false),
    );
    final partialRight = partialSource.copyWith(
      id: 'm1-oracle-partial-right',
      points: partialSource.points.skip(5).toList(growable: false),
    );
    previous = await _applyAndRecord(
      bloc,
      previous,
      'partial-erase',
      ElementsChanged({
        partialSource.id!: [partialLeft, partialRight],
      }),
      steps,
      expectedPresent: const {
        'm1-oracle-partial-left',
        'm1-oracle-partial-right',
      },
      expectedAbsent: const {'m1-oracle-partial-source'},
    );

    final translateSource = _oracleStroke('m1-oracle-translate', 1000020);
    previous = await _applyAndRecord(
      bloc,
      previous,
      'translate-selection-setup',
      ElementsCreated([translateSource]),
      steps,
      expectedPresent: const {'m1-oracle-translate'},
    );
    final translated = translateSource.copyWith(
      points: translateSource.points
          .map((point) => PathPoint(point.x + 40, point.y + 25, point.pressure))
          .toList(growable: false),
    );
    previous = await _applyAndRecord(
      bloc,
      previous,
      'translate-selection',
      ElementsChanged({
        translateSource.id!: [translated],
      }),
      steps,
      expectedElements: {translateSource.id!: translated},
    );

    previous = await _historyAndRecord(
      bloc,
      previous,
      'undo-translate',
      undo: true,
      steps: steps,
      expectedElements: {translateSource.id!: translateSource},
    );
    previous = await _historyAndRecord(
      bloc,
      previous,
      'redo-translate',
      undo: false,
      steps: steps,
      expectedElements: {translateSource.id!: translated},
    );
    previous = await _historyAndRecord(
      bloc,
      previous,
      'undo-before-branch',
      undo: true,
      steps: steps,
      expectedElements: {translateSource.id!: translateSource},
    );

    final branch = _oracleStroke('m1-oracle-branch', 1000030);
    previous = await _applyAndRecord(
      bloc,
      previous,
      'create-after-undo-branch',
      ElementsCreated([branch]),
      steps,
      expectedPresent: const {'m1-oracle-branch'},
    );
    if (bloc.canRedo) {
      throw StateError('Creating after undo must clear the Legacy redo branch');
    }

    final cancelBefore = previous;
    final cancelAfter = _snapshot(_loaded(bloc));
    if (cancelAfter.hash != cancelBefore.hash) {
      throw StateError('Cancellation contract produced a stable mutation');
    }
    steps.add(
      _record(
        'cancel-no-commit',
        cancelBefore,
        cancelAfter,
        bloc,
        ownerAction: 'foreground cancellation; no DocumentEvent emitted',
      ),
    );
    previous = cancelAfter;

    final savedBytes = await _loaded(bloc).saveBytes();
    final reopened = NoteData.fromData(savedBytes);
    final reopenedPage = reopened.getPage(_loaded(bloc).pageName);
    if (reopenedPage == null) {
      throw StateError('Saved M1 page was not present after reload');
    }
    final roundTrip = _snapshotPage(
      reopenedPage,
      currentLayer: _loaded(bloc).currentLayer,
    );
    if (roundTrip.hash != previous.hash) {
      throw StateError(
        'Save/reload normalized state mismatch: '
        '${previous.hash} != ${roundTrip.hash}',
      );
    }
    steps.add(
      _record(
        'save-reload',
        previous,
        roundTrip,
        bloc,
        ownerAction: 'DocumentLoaded.saveBytes + NoteData.fromData',
      ),
    );

    if (request.exerciseRenderingOwners) {
      await bloc.rayCastRect(const Rect.fromLTWH(0, 0, 256, 256));
      await bloc.bake(reset: true);
    }

    return M1LegacyReplayResult(
      fixture: request.fixture.label,
      run: request.run,
      startedAt: startedAt,
      finishedAt: DateTime.now().toUtc(),
      initialFixtureHash: initialFixtureHash,
      steps: steps,
    );
  }

  Future<_NormalizedSnapshot> _applyAndRecord(
    DocumentBloc bloc,
    _NormalizedSnapshot before,
    String name,
    DocumentEvent event,
    List<Map<String, Object?>> steps, {
    Set<String> expectedPresent = const {},
    Set<String> expectedAbsent = const {},
    Map<String, PadElement> expectedElements = const {},
  }) async {
    final stateFuture = bloc.stream
        .where((state) => state is DocumentLoadSuccess)
        .cast<DocumentLoadSuccess>()
        .first
        .timeout(const Duration(seconds: 30));
    M1Trace.sync('m1.oracle.$name', () => bloc.add(event));
    await stateFuture;
    await _waitForRendererOwner(
      bloc,
      expectedPresent: expectedPresent,
      expectedAbsent: expectedAbsent,
      expectedElements: expectedElements,
    );
    _sequenceRevision++;
    _historyPosition++;
    _historyHead = _historyPosition;
    final after = _snapshot(_loaded(bloc));
    steps.add(_record(name, before, after, bloc));
    return after;
  }

  Future<_NormalizedSnapshot> _historyAndRecord(
    DocumentBloc bloc,
    _NormalizedSnapshot before,
    String name, {
    required bool undo,
    required List<Map<String, Object?>> steps,
    Map<String, PadElement> expectedElements = const {},
  }) async {
    if (undo ? !bloc.canUndo : !bloc.canRedo) {
      throw StateError('$name is not reachable in the Legacy history stack');
    }
    final stateFuture = bloc.stream
        .where((state) => state is DocumentLoadSuccess)
        .cast<DocumentLoadSuccess>()
        .first
        .timeout(const Duration(seconds: 30));
    if (undo) {
      bloc.sendUndo();
      _historyPosition--;
    } else {
      bloc.sendRedo();
      _historyPosition++;
    }
    await stateFuture;
    await _waitForRendererOwner(bloc, expectedElements: expectedElements);
    _sequenceRevision++;
    final after = _snapshot(_loaded(bloc));
    steps.add(_record(name, before, after, bloc));
    return after;
  }

  Future<void> _waitForRendererOwner(
    DocumentBloc bloc, {
    Set<String> expectedPresent = const {},
    Set<String> expectedAbsent = const {},
    Map<String, PadElement> expectedElements = const {},
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (true) {
      final byId = {
        for (final renderer in bloc.currentIndexCubit.renderers)
          if (renderer.element.id != null)
            renderer.element.id!: renderer.element,
      };
      final present = expectedPresent.every(byId.containsKey);
      final absent = expectedAbsent.every((id) => !byId.containsKey(id));
      final elementsMatch = expectedElements.entries.every((entry) {
        final actual = byId[entry.key];
        return actual != null &&
            _canonicalJson(actual.toJson()) ==
                _canonicalJson(entry.value.toJson());
      });
      if (present && absent && elementsMatch) return;
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Renderer owner did not settle for M1 replay');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Map<String, Object?> _record(
    String name,
    _NormalizedSnapshot before,
    _NormalizedSnapshot after,
    DocumentBloc bloc, {
    String? ownerAction,
  }) {
    final created =
        after.elements.keys
            .where((id) => !before.elements.containsKey(id))
            .toList()
          ..sort();
    final removed =
        before.elements.keys
            .where((id) => !after.elements.containsKey(id))
            .toList()
          ..sort();
    final updated =
        after.elements.keys
            .where(
              (id) =>
                  before.elements.containsKey(id) &&
                  before.elements[id] != after.elements[id],
            )
            .toList()
          ..sort();
    final record = <String, Object?>{
      'name': name,
      'sequenceRevision': _sequenceRevision,
      'historyPosition': _historyPosition,
      'historyHead': _historyHead,
      'canUndo': bloc.canUndo,
      'canRedo': bloc.canRedo,
      'stateHash': after.hash,
      'elementCount': after.elementCount,
      'layerOrder': after.layerOrder,
      'delta': {
        'created': created,
        'updated': updated,
        'removed': removed,
        'changedPayloads': {
          for (final id in [...created, ...updated])
            id: jsonDecode(after.elements[id]!),
        },
      },
    };
    if (ownerAction != null) record['ownerAction'] = ownerAction;
    return record;
  }
}

DocumentLoadSuccess _loaded(DocumentBloc bloc) {
  final state = bloc.state;
  if (state is! DocumentLoadSuccess) {
    throw StateError('M1 Legacy replay requires DocumentLoadSuccess');
  }
  return state;
}

PenElement _oracleStroke(String id, int index) => buildM1Stroke(
  index,
  M1DeterministicRandom(m1FixtureSeed ^ index),
  idPrefix: id,
).copyWith(id: id);

_NormalizedSnapshot _snapshot(DocumentLoadSuccess state) =>
    _snapshotPage(state.page, currentLayer: state.currentLayer);

_NormalizedSnapshot _snapshotPage(
  DocumentPage page, {
  required String currentLayer,
}) => M1Trace.sync(
  M1TraceName.legacyOracleNormalize,
  () => _snapshotPageUntraced(page, currentLayer: currentLayer),
);

_NormalizedSnapshot _snapshotPageUntraced(
  DocumentPage page, {
  required String currentLayer,
}) {
  final elements = <String, String>{};
  final layerOrder = <String, List<String>>{};
  for (final layer in page.layers) {
    final layerId = layer.id;
    if (layerId == null || layerId.isEmpty) {
      throw StateError('M1 oracle requires stable non-empty layer IDs');
    }
    final ids = <String>[];
    for (final element in layer.content) {
      final id = element.id;
      if (id == null || id.isEmpty) {
        throw StateError('M1 oracle requires stable non-empty element IDs');
      }
      if (elements.containsKey(id)) {
        throw StateError('Duplicate element ID in M1 oracle: $id');
      }
      ids.add(id);
      elements[id] = _canonicalJson(element.toJson());
    }
    layerOrder[layerId] = ids;
  }
  final sortedIds = elements.keys.toList()..sort();
  final canonical = StringBuffer()
    ..write('currentLayer=')
    ..writeln(currentLayer);
  for (final layer in layerOrder.entries) {
    canonical
      ..write('layer=')
      ..write(layer.key)
      ..write(':')
      ..writeln(layer.value.join(','));
  }
  for (final id in sortedIds) {
    canonical
      ..write(id)
      ..write('=')
      ..writeln(elements[id]);
  }
  return _NormalizedSnapshot(
    hash: m1Fnv1a64Hex(utf8.encode(canonical.toString())),
    elementCount: elements.length,
    layerOrder: layerOrder,
    elements: elements,
  );
}

String _canonicalJson(Object? value) => jsonEncode(_normalize(value));

Object? _normalize(Object? value) {
  if (value is double) {
    if (!value.isFinite) {
      throw StateError('Non-finite double in M1 canonical state: $value');
    }
    final quantized = (value * 1000000).round() / 1000000;
    return quantized == 0 ? 0 : quantized;
  }
  if (value is num || value is bool || value is String || value == null) {
    return value;
  }
  if (value is List) return value.map(_normalize).toList(growable: false);
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _normalize(value[key])};
  }
  throw StateError('Unsupported M1 canonical value: ${value.runtimeType}');
}
