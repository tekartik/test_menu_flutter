# tekartik_test_menu_flutter

A manual test menu as a Flutter app: declare items and sub menus
(`tekartik_test_menu`), run them by hand on a real device or emulator
(plugins, permissions, network, storage) and read their output in a console
page. It also shows unchanged `package:test` files as a menu.

The console page has the output log, the menu, a keypad and a command line
(item number or shortcut, `-` back, `?` help), the same design as the web
test menu. The theme and the menu layout are saved in the shared
preferences. Flutter on Android, iOS, Linux, macOS, Windows and the web.

## Getting started

Not on pub.dev, a git dependency (often in a small `*_test_app`, or a
`lib/test_main.dart` entry point of the app):

```yaml
dependencies:
  tekartik_test_menu_flutter:
    git:
      url: https://github.com/tekartik/test_menu_flutter
      path: test_menu_flutter
    version: '>=1.3.0'
```

```dart
// lib/test_main.dart: flutter run -t lib/test_main.dart
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenuFlutter(() {
    item('hello', () => write('Hello'));
    item('ask', () async {
      var name = await prompt('Your name');
      write('Hello $name');
    });
    menu('sub menu', () {
      enter(() => write('entering'));
      leave(() => write('leaving'));
      item('fail', () => fail('it failed'));
    });
    group('checks', () {
      test('add', () => expect(1 + 1, 2));
    });
  });
}
```

`mainMenuFlutter` runs the app itself (`runApp`), do not embed it in another
app. See [test_menu_flutter_example/lib/main.dart](../test_menu_flutter_example/lib/main.dart).

## Unchanged test files as a menu

`mainDevTestMenuFlutter` captures the tests that a `package:test` (or
flutter_test `test`/`group`, or dev_test) `main` declares and shows them in
the menu, to run them in a real app: run one, a group or all of them, rerun
the last run or the failed tests. They run with test_api (`expect`,
`setUp`/`tearDown` of every parent group, `addTearDown`, timeouts, `skip`,
`testOn`); a group's `setUpAll` runs once per session, `reset` runs the
`tearDownAll`. `testWidgets` is not supported.

```dart
import 'package:tekartik_test_menu_flutter/dev_test_menu.dart';

import 'my_test.dart' as my_test;

Future<void> main() => mainDevTestMenuFlutter(my_test.main);
```

See [dev_test_menu_main.dart](../test_menu_flutter_example/lib/dev_test_menu_main.dart).

## Good to know

- Import `package:tekartik_test_menu_flutter/test.dart`: it has the whole
  declaration API (`menu`, `item`, `test`, `group`, `enter`, `leave`,
  `enterItem`, `leaveItem`, `command`, `write`, `prompt`, `showMenu`,
  `expect`, `fail` and the matchers) and the Flutter entry points.
- `prompt()` is answered by the next line typed in the command line.
- The tests of a `group` menu run when it is first shown; the play button of
  a group runs them all again.
- `buildContext` and `navigator` push a page from an item:
  `Navigator.push(buildContext!, MaterialPageRoute(...))`.
- `showMenu` also exists in `package:flutter/material.dart`: hide one of
  them (`import 'package:flutter/material.dart' hide showMenu;`).
- `testUiFlutterMain` (`test_ui.dart`), the older way to show `package:test`
  declarations, runs the test bodies as plain items: the `expect` of
  `package:test` (or dev_test) then throws `OutsideTestException`, even when
  it passes. Use `mainDevTestMenuFlutter` for such files.
- An LLM agent can drive the menu (the `app-agent` MCP server, `menu` and
  `menu_line` tools): over the VM service of a debug run, or on the web with
  `?agent` in the url.
