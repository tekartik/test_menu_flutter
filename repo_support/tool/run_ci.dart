import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future<void> main() async {
  for (var dir in [
    'test_menu_flutter',
    'test_menu_flutter_example',
    'repo_support',
    join('example', 'min_app'),
  ]) {
    await packageRunCi(join('..', dir));
  }
}
