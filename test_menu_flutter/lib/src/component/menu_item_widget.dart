import 'package:flutter/material.dart';
import 'package:tekartik_test_menu_flutter/src/model/item.dart';

class MenuItemWidget extends StatefulWidget {
  final Menu menu;
  final dynamic Function(Menu menu)? onTap; // = Function(MainItem item);
  final dynamic Function(Menu menu)? onPlay;

  const MenuItemWidget(this.menu, {super.key, this.onTap, this.onPlay});

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  @override
  Widget build(BuildContext context) {
    Color? color;
    IconData? icon;
    switch (widget.menu.state) {
      case ItemState.running:
        icon = Icons.more_horiz;
        break;
      case ItemState.success:
        icon = Icons.check;
        color = Colors.green;
        break;
      case ItemState.failure:
        icon = Icons.close;
        color = Colors.red;
        break;
      case ItemState.idle:
        icon = Icons.play_arrow;
        color = Colors.grey;
        break;
    }
    var widgets = <Widget>[
      IconButton(
        icon: Icon(
          Icons.menu,
          color: widget.menu.group ? Colors.black12 : Colors.grey,
        ),

        onPressed: null, // null disables the button
      ),
    ];
    if (widget.menu.group) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: IconButton(
            icon: Icon(icon, color: color),

            onPressed: _onPlay, // null disables the button
          ),
        ),
      );
    }
    return ListTile(
      leading: Stack(children: widgets),
      title: Text(widget.menu.name),
      /*
        subtitle: widget.item?.description == null
            ? null
            : new Text(widget.item.description),
            */
      onTap: _onTap,
    );
  }

  void _onTap() {
    widget.onTap!(widget.menu);

    //print(widget.item.route);
    //Navigator.pushNamed(context, widget.item.route);
  }

  void _onPlay() {
    widget.onPlay!(widget.menu);
  }
}
