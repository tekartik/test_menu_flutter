@TestOn('vm')
import 'package:test/test.dart';
import 'package:process_run/shell_run.dart';
import 'package:tekartik_build_utils/android/android_import.dart';
import 'package:tekartik_build_utils/flutter/app/generate.dart';
import 'package:tekartik_build_utils/flutter/flutter.dart';
import 'package:path/path.dart';

void main() {
  group(
    'min_app',
    () {
      test('fs_generate', () async {
        var dirName = join(
            '.dart_tool', 'test_menu_flutter', 'test', 'app', 'gen_min_app');

        var src = join('..', 'example', 'min_app');
        await fsGenerate(dir: dirName, src: src);
        expect(await File(join(dirName, 'pubspec.yaml')).readAsString(),
            await File(join(src, 'pubspec.yaml')).readAsString());
        var context = await flutterContext;
        if (context.supportsWeb) {
          await Shell(workingDirectory: dirName).run('flutter build web');
        }
      });
    },
    skip: !isFlutterSupported,
    // Allow 10 mn for web build (sdk download)
    timeout: Timeout(Duration(minutes: 10)),
  );
}
