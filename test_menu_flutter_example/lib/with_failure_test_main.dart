import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  initTestMenuFlutter();

  group('super', () {
    group('failure', () {
      test('failure', () {
        write('failure');
        fail('failure');
      });
      test('success', () {
        expect(true, isTrue);
        write('success');
      });
    });
    group('success', () {
      test('success', () {
        expect(true, isTrue);
        write('success');
      });
    });
  });
}
