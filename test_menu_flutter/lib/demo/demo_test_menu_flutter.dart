import 'package:flutter/material.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

import 'common_test_menu.dart' as common;

void main() {
  menu('flutter', () {
    item('navigate', () {
      Navigator.push(buildContext,
          MaterialPageRoute(builder: (BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text("test")),
            body: demoSimpleList(context));
      }));
    });
  });
  common.main();
}
