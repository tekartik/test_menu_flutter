import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenuFlutter(appMainMenu, showConsole: true);
}

var _soloTestCount = 0;
void appMainMenu() {
  // ignore: invalid_use_of_do_not_submit_member
  solo_test('some test', () {
    write('test ${++_soloTestCount}');
  });
}
