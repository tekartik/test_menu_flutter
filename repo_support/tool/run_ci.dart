import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> main() async {
  if (dartVersion >= Version(2, 12, 0, pre: '0')) {
    for (var dir in [
      'test_menu_flutter',
      'test_menu_flutter_example',
    ]) {
      await packageRunCi(join('..', dir));
    }
  }
}
