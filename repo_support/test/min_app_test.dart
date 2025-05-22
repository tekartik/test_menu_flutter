@TestOn('vm')
library;

import 'package:process_run/shell_run.dart';
import 'package:tekartik_build_utils/android/android_import.dart';
import 'package:tekartik_build_utils/flutter/app/generate.dart';
import 'package:tekartik_build_utils/flutter/flutter.dart';
import 'package:test/test.dart';

void main() {
  test('dummy', () {
    // Prevent no test failure
  });
  group(
    'min_app',
    () {
      test('fs_generate', () async {
        var dirName = join(
          '.dart_tool',
          'test_menu_flutter',
          'test',
          'app',
          'gen_min_app',
        );

        var src = join('..', 'example', 'min_app');
        await fsGenerate(dir: dirName, src: src);
        var context = await flutterContext;
        if (context.supportsWeb!) {
          await Shell(workingDirectory: dirName).run('flutter build web');
        }
      });
    },
    skip: !isFlutterSupported,
    // Allow 10 mn for web build (sdk download)
    timeout: Timeout(Duration(minutes: 10)),
  );
}
