import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenuFlutter(appMainMenu, showConsole: true);
}

var _soloTestCount = 0;
void appMainMenu() {
  // ignore: deprecated_member_use
  solo_test('some test', () {
    write('test ${++_soloTestCount}');
  });
}
