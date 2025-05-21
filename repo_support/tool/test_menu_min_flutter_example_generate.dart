import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_utils/flutter/app/generate.dart';

Future main() async {
  var dirName = join('..', 'example', 'min_app');
  try {
    await Directory(dirName).delete(recursive: true);
  } catch (_) {}
  //expect(Directory(dirName).existsSync(), isFalse);
  await gitGenerate(
    dirName: dirName,
    appName: 'tekartik_test_menu_flutter_min_app',
  );
}
