import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:butterfly/debug/performance/m1_fixture.dart';

void main(List<String> args) {
  final output = Directory(args.isEmpty ? 'build/m1-fixtures' : args.first)
    ..createSync(recursive: true);
  final fixtures = <String, Uint8List>{
    for (final fixture in M1FixtureId.values)
      fixture.label: generateM1FixtureBytes(fixture.label),
    'FPAGE': generateM1FixtureBytes('FPAGE'),
  };
  final manifest = <String, Object?>{
    'schema': 'notea.m1.fixtures/v1',
    'seed': m1FixtureSeed,
    'fixtures': <String, Object?>{},
  };
  for (final entry in fixtures.entries) {
    final file = File('${output.path}/${entry.key}.tbfly');
    file.writeAsBytesSync(entry.value, flush: true);
    (manifest['fixtures']! as Map<String, Object?>)[entry.key] = {
      'path': file.path,
      'bytes': entry.value.length,
      'fnv1a64': m1Fnv1a64Hex(entry.value),
    };
  }
  File('${output.path}/manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
    flush: true,
  );
}
