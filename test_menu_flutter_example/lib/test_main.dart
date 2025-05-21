import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/demo/demo_test_menu_flutter.dart'
    as demo;
import 'package:tekartik_test_menu_flutter/test.dart';
import 'package:tekartik_test_menu_flutter_example/common_test.dart';

void main() {
  initTestMenuFlutter();

  /*
  test('crash', () {
    fail('fail');
  });
  */
  group('group', () {
    test('success', () {
      expect(true, isTrue);
      write('success');
    });
  });

  menu('group menus', () {
    group('group1', () {
      group('sub_group1', () {
        test('test', () {});
      });
      group('sub_group1', () {
        test('test', () {});
      });
    });
  });

  demo.main();

  menu('custom', () {
    item('do it', () {
      write('ok');
      write('or no');
    });
    test('success', () {
      expect(true, isTrue);
      write('success');
    });
  });
  menu('group', () {
    test('failure', () {
      fail('failure');
    });

    test('expect_failure', () {
      write('failure');
      expect(true, isFalse);
    });
    test('success', () {
      expect(true, isTrue);
      write('success');
    });

    test('throw', () {
      throw 'error thrown';
    });
  });
  item('root_item', () {
    write('from root item');
  });
  item('sleep 1000', () async {
    write('before sleep');
    await sleep(2000);
    write('after sleep 2000');
  });
  item('navigate', () {
    Navigator.push(
      buildContext!,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: const Text('test')),
            body: demoSimpleList(context),
          );
        },
      ),
    );
  });
  menu('testCommon', () {
    testCommon();
  });
}
