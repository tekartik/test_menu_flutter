import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

Future main() async {
  var shell = Shell();

  await packageRunCi('.');

  for (var dir in [
    'test_menu_flutter',
    'test_menu_flutter_example',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
    flutter packages get
    dart tool/travis.dart
    
        ''');
    shell = shell.popd();
  }
}
