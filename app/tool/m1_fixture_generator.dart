import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:butterfly_api/butterfly_api.dart';

final class DeterministicRandom {
  int _state;
  DeterministicRandom(this._state);

  int next() {
    _state = ((_state * 1664525) + 1013904223) & 0xffffffff;
    return _state;
  }

  double unit() => next() / 0xffffffff;
}

BigInt fnv1a64(Uint8List bytes) {
  final mask = (BigInt.one << 64) - BigInt.one;
  final prime = BigInt.parse('100000001b3', radix: 16);
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  for (final byte in bytes) {
    hash ^= BigInt.from(byte);
    hash = (hash * prime) & mask;
  }
  return hash;
}

PenElement stroke(int index, DeterministicRandom random, {int samples = 8}) {
  final originX = (index % 500) * 6.0;
  final originY = (index ~/ 500) * 5.0;
  return PenElement(
    id: 'm1-stroke-${index.toString().padLeft(7, '0')}',
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

Uint8List singlePageFixture(int count, int seed, {int samples = 8}) {
  final random = DeterministicRandom(seed);
  final page = DocumentPage(
    layers: [
      DocumentLayer(
        id: 'm1-layer',
        content: List.generate(
          count,
          (index) => stroke(index, random, samples: samples),
          growable: false,
        ),
      ),
    ],
  );
  final (data, _) = NoteData(Archive()).setPage(page, 'M1');
  return data.exportAsTextBytes();
}

Uint8List pagedFixture(int pageCount, int strokesPerPage, int seed) {
  final random = DeterministicRandom(seed);
  var data = NoteData(Archive());
  var strokeIndex = 0;
  for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
    final page = DocumentPage(
      layers: [
        DocumentLayer(
          id: 'm1-layer-$pageIndex',
          content: List.generate(strokesPerPage, (_) {
            return stroke(strokeIndex++, random);
          }, growable: false),
        ),
      ],
    );
    (data, _) = data.setPage(page, 'Page ${pageIndex + 1}');
  }
  return data.exportAsTextBytes();
}

void main(List<String> args) {
  final output = Directory(args.isEmpty ? 'build/m1-fixtures' : args.first)
    ..createSync(recursive: true);
  const seed = 0x4e4f5445;
  final fixtures = <String, Uint8List>{
    'F0': singlePageFixture(0, seed),
    'F1': singlePageFixture(1000, seed),
    'F10': singlePageFixture(10000, seed),
    'F50': singlePageFixture(50000, seed),
    'F200': singlePageFixture(200000, seed),
    'FLONG': singlePageFixture(1, seed, samples: 20000),
    'FFRAG': singlePageFixture(50000, seed, samples: 2),
    'FPAGE': pagedFixture(100, 100, seed),
  };
  final manifest = <String, Object?>{
    'schema': 'notea.m1.fixtures/v1',
    'seed': seed,
    'fixtures': <String, Object?>{},
  };
  for (final entry in fixtures.entries) {
    final file = File('${output.path}/${entry.key}.tbfly');
    file.writeAsBytesSync(entry.value, flush: true);
    (manifest['fixtures']! as Map<String, Object?>)[entry.key] = {
      'path': file.path,
      'bytes': entry.value.length,
      'fnv1a64': fnv1a64(entry.value).toRadixString(16).padLeft(16, '0'),
    };
  }
  File('${output.path}/manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
    flush: true,
  );
}
