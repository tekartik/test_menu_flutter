import 'package:flutter/material.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';
import 'common_test_menu.dart' as common;

main() {
  menu('flutter', () {
    item('navigate', () {
      Navigator.push(buildContext,
          new MaterialPageRoute(builder: (BuildContext context) {
        return new Scaffold(
            appBar: new AppBar(title: new Text("test")),
            body: demoSimpleList(context));
      }));
    });
  });
  common.main();
}
