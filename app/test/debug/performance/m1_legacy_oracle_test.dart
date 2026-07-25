import 'dart:convert';

import 'package:butterfly_api/butterfly_api.dart';
import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/cubits/current_index.dart';
import 'package:butterfly/cubits/settings.dart';
import 'package:butterfly/cubits/transform.dart';
import 'package:butterfly/debug/performance/m1_fixture.dart';
import 'package:butterfly/debug/performance/m1_legacy_oracle.dart';
import 'package:butterfly/models/viewport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:material_leap/material_leap.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

final class _Harness {
  _Harness({
    required this.bloc,
    required this.currentIndex,
    required this.window,
  });

  final DocumentBloc bloc;
  final CurrentIndexCubit currentIndex;
  final WindowCubit window;

  Future<void> close() async {
    if (!bloc.isClosed) await bloc.close();
    if (!currentIndex.isClosed) await currentIndex.close();
    if (!window.isClosed) await window.close();
  }
}

_Harness createHarness(M1FixtureId fixture) {
  final fileSystem = MockButterflyFileSystem();
  final settings = fileSystem.settingsCubit as MockSettingsCubit;
  when(
    () => settings.state,
  ).thenReturn(const ButterflySettings(autosave: false));
  when(() => settings.stream).thenAnswer((_) => const Stream.empty());
  final currentIndex = CurrentIndexCubit(
    settings,
    TransformCubit(1),
    const CameraViewport.unbaked(),
  );
  final window = WindowCubit(fullScreen: false);
  final data = buildM1SinglePageFixture(fixture);
  final pageName = data.getPages(true).single;
  final page = data.getPage(pageName)!;
  final bloc = DocumentBloc(
    fileSystem,
    currentIndex,
    window,
    data,
    const AssetLocation(path: 'm1-oracle.tbfly'),
    null,
    page,
    pageName,
  );
  return _Harness(bloc: bloc, currentIndex: currentIndex, window: window);
}

Future<M1LegacyReplayResult> runOracle() async {
  final harness = createHarness(M1FixtureId.empty);
  try {
    return await M1LegacyOracleRunner().run(
      harness.bloc,
      const M1LegacyReplayRequest(
        fixture: M1FixtureId.empty,
        run: 1,
        exerciseRenderingOwners: false,
      ),
    );
  } finally {
    await harness.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shared M1 fixture generation is deterministic', () {
    final first = generateM1FixtureBytes('F1');
    final second = generateM1FixtureBytes('f1');
    expect(m1Fnv1a64Hex(first), m1Fnv1a64Hex(second));
    expect(first, orderedEquals(second));

    final reopened = NoteData.fromData(first);
    expect(reopened.getMetadata()?.type, NoteFileType.document);
    expect(reopened.getMetadata()?.fileVersion, kFileVersion);
    expect(reopened.getPages(true), ['M1']);
  });

  test(
    'Legacy oracle covers mutations, history, cancellation and reload',
    () async {
      final result = await runOracle();
      final byName = {
        for (final step in result.steps) step['name']! as String: step,
      };

      expect(
        byName.keys,
        containsAll([
          'create-stroke',
          'erase-strokes',
          'partial-erase',
          'translate-selection',
          'undo-translate',
          'redo-translate',
          'create-after-undo-branch',
          'cancel-no-commit',
          'save-reload',
        ]),
      );
      expect((byName['create-stroke']!['delta']! as Map)['created'], [
        'm1-oracle-create',
      ]);
      expect((byName['erase-strokes']!['delta']! as Map)['removed'], [
        'm1-oracle-create',
      ]);
      expect((byName['partial-erase']!['delta']! as Map)['created'], [
        'm1-oracle-partial-left',
        'm1-oracle-partial-right',
      ]);
      expect(byName['create-after-undo-branch']!['canRedo'], isFalse);
      expect(
        byName['cancel-no-commit']!['stateHash'],
        byName['create-after-undo-branch']!['stateHash'],
      );
      expect(
        byName['save-reload']!['stateHash'],
        byName['cancel-no-commit']!['stateHash'],
      );
    },
  );

  test(
    'Legacy oracle state hashes are deterministic across fresh runs',
    () async {
      final first = await runOracle();
      final second = await runOracle();
      expect(
        first.steps.map((step) => step['stateHash']),
        orderedEquals(second.steps.map((step) => step['stateHash'])),
      );
      expect(
        jsonEncode(first.steps.map((step) => step['delta']).toList()),
        jsonEncode(second.steps.map((step) => step['delta']).toList()),
      );
    },
  );
}
