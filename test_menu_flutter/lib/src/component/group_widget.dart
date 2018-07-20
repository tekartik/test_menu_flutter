import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../model/main_item.dart';

class GroupWidget extends StatefulWidget {
  final MainItem item;
  final Function onTap; // = Function(MainItem item);
  GroupWidget(this.item, this.onTap);

  @override
  _GroupWidgetState createState() => new _GroupWidgetState();
}

class _GroupWidgetState extends State<GroupWidget> {
  @override
  Widget build(BuildContext context) {
    return new ListTile(
        leading: new IconButton(
          icon: new Icon(Icons.menu, color: Colors.grey),

          onPressed: null, // null disables the button
        ),
        title: new Text(widget.item.title),
        subtitle: widget.item?.description == null
            ? null
            : new Text(widget.item.description),
        onTap: _onTap);
  }

  void _onTap() {
    widget.onTap(widget.item);

    //print(widget.item.route);
    //Navigator.pushNamed(context, widget.item.route);
  }
}
