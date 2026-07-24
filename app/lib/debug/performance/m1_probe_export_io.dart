import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> writeM1ProbeJsonl(String contents, String sessionId) async {
  final root = await getApplicationDocumentsDirectory();
  final directory = Directory('${root.path}/m1-probe');
  await directory.create(recursive: true);
  final file = File('${directory.path}/$sessionId.jsonl');
  await file.writeAsString(contents, flush: true);
  return file.path;
}
