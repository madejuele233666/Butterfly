import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:butterfly_api/butterfly_api.dart';

const m1FixtureSeed = 0x4e4f5445;

enum M1FixtureId {
  empty('F0', 0, 8),
  normal('F1', 1000, 8),
  heavy('F10', 10000, 8),
  stress('F50', 50000, 8),
  extreme('F200', 200000, 8),
  longStroke('FLONG', 1, 20000),
  fragmented('FFRAG', 50000, 2);

  const M1FixtureId(this.label, this.strokeCount, this.samplesPerStroke);

  final String label;
  final int strokeCount;
  final int samplesPerStroke;

  static M1FixtureId? fromLabel(String value) {
    final normalized = value.toUpperCase();
    for (final fixture in values) {
      if (fixture.label == normalized) return fixture;
    }
    return null;
  }
}

final class M1DeterministicRandom {
  int _state;

  M1DeterministicRandom(this._state);

  int next() {
    _state = ((_state * 1664525) + 1013904223) & 0xffffffff;
    return _state;
  }

  double unit() => next() / 0xffffffff;
}

BigInt m1Fnv1a64(List<int> bytes) {
  final mask = (BigInt.one << 64) - BigInt.one;
  final prime = BigInt.parse('100000001b3', radix: 16);
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  for (final byte in bytes) {
    hash ^= BigInt.from(byte);
    hash = (hash * prime) & mask;
  }
  return hash;
}

String m1Fnv1a64Hex(List<int> bytes) =>
    m1Fnv1a64(bytes).toRadixString(16).padLeft(16, '0');

PenElement buildM1Stroke(
  int index,
  M1DeterministicRandom random, {
  int samples = 8,
  String idPrefix = 'm1-stroke',
}) {
  final originX = (index % 500) * 6.0;
  final originY = (index ~/ 500) * 5.0;
  return PenElement(
    id: '$idPrefix-${index.toString().padLeft(7, '0')}',
    points: List.generate(samples, (point) {
      final progress = point / (samples - 1).clamp(1, samples);
      return PathPoint(
        originX + point * 1.7 + random.unit() * 0.01,
        originY + progress * 3.0 + random.unit() * 0.01,
        0.2 + progress * 0.7,
      );
    }, growable: false),
  );
}

NoteData buildM1SinglePageFixture(M1FixtureId fixture) {
  final random = M1DeterministicRandom(m1FixtureSeed);
  final page = DocumentPage(
    layers: [
      DocumentLayer(
        id: 'm1-layer',
        content: List.generate(
          fixture.strokeCount,
          (index) => buildM1Stroke(
            index,
            random,
            samples: fixture.samplesPerStroke,
          ),
          growable: false,
        ),
      ),
    ],
  );
  final (data, _) = NoteData(Archive()).setPage(page, 'M1');
  return data;
}

NoteData buildM1PagedFixture({
  int pageCount = 100,
  int strokesPerPage = 100,
}) {
  final random = M1DeterministicRandom(m1FixtureSeed);
  var data = NoteData(Archive());
  var strokeIndex = 0;
  for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
    final page = DocumentPage(
      layers: [
        DocumentLayer(
          id: 'm1-layer-$pageIndex',
          content: List.generate(
            strokesPerPage,
            (_) => buildM1Stroke(strokeIndex++, random),
            growable: false,
          ),
        ),
      ],
    );
    (data, _) = data.setPage(page, 'Page ${pageIndex + 1}');
  }
  return data;
}

Uint8List generateM1FixtureBytes(String fixtureLabel) {
  if (fixtureLabel.toUpperCase() == 'FPAGE') {
    return buildM1PagedFixture().exportAsTextBytes();
  }
  final fixture = M1FixtureId.fromLabel(fixtureLabel);
  if (fixture == null) {
    throw ArgumentError.value(fixtureLabel, 'fixtureLabel', 'Unknown fixture');
  }
  return buildM1SinglePageFixture(fixture).exportAsTextBytes();
}
