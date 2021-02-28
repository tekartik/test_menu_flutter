import 'package:flutter/material.dart';

Widget demoSimpleList(BuildContext context, [int? count]) {
  count ??= 50;

  Widget _itemBuilder(BuildContext context, int index) {
    return ListTile(
        title: Text('Title $index'), subtitle: Text('Long description $index'));
  }

  return ListView.builder(itemBuilder: _itemBuilder, itemCount: count);
}
