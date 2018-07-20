import 'package:flutter/material.dart';
import 'package:tekartik_test_menu_flutter/src/component/menu_page.dart';
import 'package:tekartik_test_menu_flutter/src/model/main_item.dart';
import 'package:test/test.dart';

class SubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MenuPage(title: 'Sub menu', items: [
      new MainItem("Show toast", "Simple snackbar at the bottom",
          action: (BuildContext context) {
        Scaffold.of(context).showSnackBar(new SnackBar(
              content: new Text("Sending Message"),
            ));
      })
    ]);
  }
}

void main() {
  /*
  test('adds one to input values', () {
    final calculator = new Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
    expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
  */
}
