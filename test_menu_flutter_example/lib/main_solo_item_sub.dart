import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenuFlutter(appMainMenu, showConsole: true);
}

var _soloTestCount = 0;
void appMainMenu() {
  menu('menu', () {
    menu('submenu', () {
      // ignore: deprecated_member_use
      solo_item('some item', () async {
        var count = ++_soloTestCount;
        write('starting $count');
        await sleep(500);
        write('ending $count');
      });
    });
  });
}
