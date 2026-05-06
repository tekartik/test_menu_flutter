import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  initTestMenuFlutter();
  // ignore: invalid_use_of_do_not_submit_member, deprecated_member_use
  solo_menu('some test', () {
    test('test', () {
      write('test');
    });
    item('item', () {
      write('item');
    });
  });
}
