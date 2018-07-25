import 'package:flutter/material.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/demo/demo_test_menu_flutter.dart'
    as demo;
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  initTestMenuFlutter();

  /*
  test('crash', () {
    fail('fail');
  });
  */
  test('success', () {
    expect(true, isTrue);
  });

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
  group('group', () {
    test('success', () {
      expect(true, isTrue);
      write('success');
    });
  });
  item('root_item', () {
    write('from root item');
  });
  item("sleep 1000", () async {
    write('before sleep');
    await sleep(2000);
    write('after sleep 2000');
  });
  item('navigate', () {
    Navigator.push(buildContext,
        new MaterialPageRoute(builder: (BuildContext context) {
      return new Scaffold(
          appBar: new AppBar(title: new Text("test")),
          body: demoSimpleList(context));
    }));
  });
}
