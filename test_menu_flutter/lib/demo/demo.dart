import 'package:flutter/material.dart';

Widget demoSimpleList(BuildContext context, [int count]) {
  count ??= 50;

  Widget _itemBuilder(BuildContext context, int index) {
    return new ListTile(
        title: new Text("Title $index"),
        subtitle: new Text("Long description $index"));
  }

  return new ListView.builder(itemBuilder: _itemBuilder, itemCount: count);
}
