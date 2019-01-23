import 'package:flutter/material.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/demo/demo_test_menu_flutter.dart'
    as demo;
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

void main() {
  mainMenu(() {
    //devPrint('MAIN_');
    item('item2', () {
      write('item');
    });
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
          MaterialPageRoute(builder: (BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text("test")),
            body: demoSimpleList(context));
      }));
    });
  });
}
