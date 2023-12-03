// ignore: implementation_imports
import 'package:tekartik_test_menu/src/test_menu/test_menu.dart';

enum ItemState { idle, running, success, failure }

abstract class BaseItem {
  final bool autoRun;
  final TestItem testItem;

  BaseItem(this.testItem, this.autoRun);

  String get name => testItem.name;
}

class Item extends BaseItem {
  RunnableTestItem get runnableTestItem => (testItem as RunnableTestItem);

  bool? get test => runnableTestItem.test;

  dynamic Function() get action => (testItem as RunnableTestItem).fn;

  ItemState state = ItemState.idle;

  Item(super.testItem, super.autoRun);

  @override
  String toString() {
    return "$state $testItem${test == true ? ' test' : ''}";
  }
}
/*
class TestItem extends Item {
  dynamic Function() action;
  final bool test;
  TestItem(String name, {this.test}) : super(name);

}test
*/

class Menu extends BaseItem {
  MenuTestItem get menuTestItem => testItem as MenuTestItem;

  bool get group => menuTestItem.menu.group == true;
  ItemState state = ItemState.idle;

  Menu(super.testItem, super.autoRun);
}
