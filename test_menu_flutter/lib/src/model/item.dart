import 'package:func/func.dart';

enum ItemState { idle, running, success, failure }

abstract class BaseItem {
  final String name;
  BaseItem(this.name);
}

class Item extends BaseItem {
  final Func0<dynamic> action;
  ItemState state = ItemState.idle;

  Item(String name, [this.action]) : super(name);

  @override
  String toString() {
    return "$state ${name}";
  }
}

class Group extends BaseItem {
  Group(String name) : super(name);
}
