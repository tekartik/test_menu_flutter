import 'package:dev_test/package.dart';

Future main() async {
  for (var dir in [
    'test_menu_flutter',
    'test_menu_flutter_example',
  ]) {
    await packageRunCi(dir);
  }
}
