// ignore_for_file: avoid_print

import 'package:dev_test/test.dart';
import 'package:tekartik_test_menu_flutter/dev_test_menu.dart';

/// Plain test declarations, as in a test file (package:test would do too).
void sampleTests() {
  group('math', () {
    setUpAll(() => print('setUpAll math (once per session)'));
    tearDownAll(() => print('tearDownAll math (on reset)'));
    test('add', () => expect(1 + 1, 2));
    test('fail', () => expect(1 + 1, 3));
    test('async', () async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(true, isTrue);
    });
    test('skipped', () {}, skip: 'example');
  });
  test('print', () => print('hello from a test'));
}

/// The tests in the test menu: run one, a group, all, rerun the failed ones.
///
/// `flutter run -t lib/dev_test_menu_main.dart`
Future<void> main() => mainDevTestMenuFlutter(sampleTests);
