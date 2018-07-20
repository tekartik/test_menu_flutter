import 'package:tekartik_test_menu_flutter/demo/common_test_menu.dart'
    as common;
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

void main() {
  initTestMenuFlutter();
  common.main();

  menu('custom', () {
    item('do it', () {
      write('ok');
      write('or no');
    });
  });
}
