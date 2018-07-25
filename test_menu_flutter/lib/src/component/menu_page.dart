import 'package:flutter/material.dart';
import 'package:tekartik_test_menu_flutter/src/model/item.dart';

class MenuPage extends StatefulWidget {
  final List<BaseItem> items;

  MenuPage({Key key, this.title, this.items}) : super(key: key);

  final String title;

  @override
  MenuPageState createState() => new MenuPageState();
}

class MenuPageRoute extends MaterialPageRoute {
  final Widget menuPage;

  MenuPageRoute(
      {this.menuPage,
      WidgetBuilder builder,
      RouteSettings settings: const RouteSettings()})
      : super(builder: builder, settings: settings);

  static MenuPageRoute of(BuildContext context, Widget menuPage) =>
      new MenuPageRoute(
          menuPage: menuPage,
          builder: (BuildContext context) {
            return menuPage;
          });
}

class MenuPageState extends State<MenuPage> {
  get _itemCount => widget.items?.length ?? 0;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text(widget.title)),
        body: new ListView.builder(
            itemBuilder: _itemBuilder, itemCount: _itemCount));
  }

  //new Center(child: new Text('Running on: $_platformVersion\n')),

  Widget _itemBuilder(BuildContext context, int index) {
    /*
    return new MainItemWidget(widget.items[index], (MainItem item) {
      if (item is PageItem) {
        Navigator
            .of(context)
            .push(new MaterialPageRoute(builder: item.pageBuilder));
      } else {
        if (item.action != null) {
          item.action(context);
        } else {
          Navigator.of(context).pushNamed(item.route);
        }
      }
    });
    TimeOfDayFormat.HH_dot_m
    TODO
    */
    return null;
  }
}
