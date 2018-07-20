import 'package:flutter/material.dart';
import 'package:tekartik_common_utils/dev_utils.dart';
import 'package:tekartik_test_menu_flutter/src/component/group_widget.dart';
import 'package:tekartik_test_menu_flutter/src/component/item_widget.dart';
import 'package:tekartik_test_menu_flutter/src/model/item.dart';
import 'package:tekartik_test_menu_flutter/src/model/main_item.dart';

class MenuItems extends StatefulWidget {
  final List<BaseItem> items;

  MenuItems({Key key, this.title, this.items}) : super(key: key);

  final String title;

  @override
  MenuItemsState createState() => new MenuItemsState();
}

class MenuItemsState extends State<MenuItems> {
  get _itemCount => widget.items?.length ?? 0;

  @override
  initState() {
    devPrint('MenuItemsState.initState');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: _itemBuilder, itemCount: _itemCount);
  }

  //new Center(child: new Text('Running on: $_platformVersion\n')),

  Widget _itemBuilder(BuildContext context, int index) {
    var item = widget.items[index];
    if (item is MainItem) {
      return new GroupWidget(item as MainItem, (MainItem item) {
        if (item is PageItem) {
          // Navigator.of(context).push(new MaterialPageRoute(builder: item.pageBuilder));
        } else {
          if (item.action != null) {
            item.action(context);
          } else {
            // Navigator.of(context).pushNamed(item.route);
          }
        }
      });
    } else if (item is Item) {
      devPrint('item widget ${item}');
      return new ItemWidget(item, (_) async {
        // item.action();
        await _run(item);
        /*
        if (item.action != null) {
          item.action(context);
        }
        */
      });
    }
    throw 'not supported $item ${item?.runtimeType}';
  }

  _run(Item item) async {
    setState(() {
      item.state = ItemState.running;
      devPrint('running item widget ${item}');
    });
    try {
      print("#TEST Running ${item.name}");
      await item.action();
      print("TEST Done ${item.name}");

      //item = new Item("${item.name}")..state = ItemState.success;
      setState(() {
        item.state = ItemState.success;
        devPrint('success item widget ${item}');
      });
    } catch (e, st) {
      print("TEST Error $e running ${item.name}");
      try {
        //print(st);
/*        if (await Sqflite.getDebugModeOn()) {
    print(st);
    }
    */
      } catch (_) {
        setState(() {
          item..state = ItemState.failure;
          devPrint('failure item widget ${item}');
        });
      }
    }
  }
}
