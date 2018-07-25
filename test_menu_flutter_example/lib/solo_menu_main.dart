import 'package:flutter/material.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/demo/demo_test_menu_flutter.dart'
    as demo;
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
