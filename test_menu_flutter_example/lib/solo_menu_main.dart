import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  initTestMenuFlutter();
  // ignore: deprecated_member_use
  solo_menu('some test', () {
    test('test', () {
      write('test');
    });
    item('item', () {
      write('item');
    });
  });
}
