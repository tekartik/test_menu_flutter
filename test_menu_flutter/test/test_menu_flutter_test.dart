import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_test_menu_flutter/src/test_menu_manager_flutter.dart';

class SubPage extends StatelessWidget {
  const SubPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RootMenuPage();
  }
}

void main() {
  test('dummy', () {
    // Prevent no test failure
  });
}
