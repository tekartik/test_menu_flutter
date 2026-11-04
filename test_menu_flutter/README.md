# flutter_test_menu

## Setup

```
dependencies:
  tekartik_test_menu_flutter:
    git:
      url: https://github.com/tekartik/test_menu_flutter
      path: test_menu_flutter
    version: '>=0.2.3'
```

A console page with the output log, the menu, a keypad and a command line
(item number or shortcut, `-` back, `?` help), same design as the web test
menu. The theme and the menu layout (hidden, height limit) are saved in the
shared preferences.

## Quick main

See [main.dart](../test_menu_flutter_example/lib/main.dart)

## Unchanged test files as a menu

`mainDevTestMenuFlutter` captures the tests that a `package:test` (or
flutter_test `test`/`group`) `main` declares and shows them in the menu, to
run them in a real app (plugins, devices): run one, a group or all of them,
rerun the last run or the failed tests. A group's `setUpAll` runs once per
session, `reset` runs the `tearDownAll`. `testWidgets` is not supported.

```dart
import 'package:tekartik_test_menu_flutter/dev_test_menu.dart';

import 'my_test.dart' as my_test;

Future<void> main() => mainDevTestMenuFlutter(my_test.main);
```

See [dev_test_menu_main.dart](../test_menu_flutter_example/lib/dev_test_menu_main.dart).
