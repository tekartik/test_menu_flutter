import 'package:flutter/material.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/demo/demo_test_menu_flutter.dart'
    as demo;
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

void main() {
  initTestMenuFlutter();
  demo.main();

  menu('custom', () {
    item('do it', () {
      write('ok');
      write('or no');
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
