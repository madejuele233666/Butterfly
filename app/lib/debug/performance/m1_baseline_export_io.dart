import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> writeM1BaselineJson(String contents, String sessionId) async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/m1-baseline')
    ..createSync(recursive: true);
  final file = File('${directory.path}/$sessionId.json');
  await file.writeAsString(contents, flush: true);
  return file.path;
}
