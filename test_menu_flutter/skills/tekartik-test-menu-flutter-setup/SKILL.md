---
name: tekartik-test-menu-flutter-setup
description: >-
  Use when building an interactive manual test/debug menu app in Flutter with
  tekartik_test_menu_flutter: mainMenuFlutter, initTestMenuFlutter, the
  declaration API menu/item/test/group/enter/leave/enterItem/leaveItem/command/
  write/prompt/showMenu/solo_item/solo_menu/expect/fail, the buildContext and
  navigator globals to push a page from an item, showConsole, testUiFlutterMain
  from test_ui.dart to run package:test style declarations in the menu, the
  demo menus (demo/demo.dart demoSimpleList, demo/common_test_menu.dart,
  demo/demo_test_menu_flutter.dart), and the showMenu clash with
  package:flutter/material.dart.
---

# Flutter test menu app (tekartik_test_menu_flutter)

`tekartik_test_menu_flutter` turns a `tekartik_test_menu` declaration into a
runnable Flutter app: a scrollable list of items and sub menus, an output
console and a prompt dialog. It is the way to drive manual/device-only code
(plugins, auth, network, storage) by hand on a real device or emulator.

## Guidelines

* Dependency (git, not published on pub.dev):
  ```yaml
  dependencies:
    tekartik_test_menu_flutter:
      git:
        url: https://github.com/tekartik/test_menu_flutter
        path: test_menu_flutter
      version: '>=0.2.5'
  ```
  Usually in a small companion app (`*_example`, `*_test_app`) or in
  `dev_dependencies` with a `lib/test_main.dart` entry point run by
  `flutter run -t lib/test_main.dart`.
* Imports:
  * `package:tekartik_test_menu_flutter/test.dart` is the one to use: it
    re-exports `test_menu_flutter.dart` **and**
    `package:tekartik_test_menu/test.dart`, so `menu`, `item`, `test`,
    `group`, `enter`, `leave`, `enterItem`, `leaveItem`, `command`, `write`,
    `writeln`, `prompt`, `popMenu`, `expect`, `fail` and the `package:matcher`
    matchers are all available.
  * `package:tekartik_test_menu_flutter/test_menu_flutter.dart` alone exports
    only the flutter entry points plus `menu`, `item`, `command`, `enter`,
    `leave`, `enterItem`, `leaveItem`, `write`, `showMenu`, `solo_item`,
    `solo_menu`, `navigator`, `buildContext`. `prompt`, `writeln`, `popMenu`,
    `test`, `group` and `expect` are *not* in it.
  * `package:tekartik_test_menu_flutter/test_ui.dart`: `testUiFlutterMain`.
  * `package:tekartik_test_menu_flutter/demo/demo.dart`:
    `demoSimpleList(context, [count])`, a throwaway `ListView` to push.
    `demo/common_test_menu.dart` and `demo/demo_test_menu_flutter.dart` each
    expose a `main()` declaring a ready-made demo menu to fold into yours.
* Entry point: `void main() => mainMenuFlutter(declare, {showConsole});`.
  `mainMenuFlutter` calls `runApp` itself with its own `MaterialApp`, so do
  not call `runApp` too and do not expect to embed the menu in an existing
  app: the page widgets are not exported. `initTestMenuFlutter({builder,
  showConsole})` is the lower level variant (it runs the app, then you
  declare right after in `main()`); `builder` wraps the menu app, for an
  inherited widget or a provider scope. `mainMenu` is the deprecated old name
  of `mainMenuFlutter`.
* Declarations are synchronous and happen once, at declaration time: call
  `menu`/`item`/`test`/`group` from the callback passed to
  `mainMenuFlutter`, never from inside a running item — build a run-time menu
  with `await showMenu(() { ... })` instead.
* `showConsole: true` shows the dark output panel where `write()`/`writeln()`
  lands (it can be toggled and cleared from the app bar); with the default
  `false` the output only shows while an item runs.
* Pushing a page from an item: the globals `buildContext` (the menu page
  context, nullable) and `navigator` (`Navigator.of(buildContext!)`) are
  exported for that, e.g.
  `Navigator.push(buildContext!, MaterialPageRoute<void>(builder: ...))`.
* Name clash: `showMenu` exists both here and in
  `package:flutter/material.dart`. In a file importing both, either write
  `import 'package:flutter/material.dart' hide showMenu;` or import the menu
  api with a prefix; otherwise the reference is ambiguous.
* `solo_item`, `solo_menu`, `solo_test`, `solo_group` (and `solo: true`) keep
  only that entry, for a fast loop; they are `@doNotSubmit`, so they need an
  `// ignore: invalid_use_of_do_not_submit_member` and must be removed before
  committing.
* `testUiFlutterMain(body)` from `test_ui.dart` runs `body` in a zone whose
  `package:test` declarer is replaced by the menu: a plain `test()`/`group()`
  declaration library (shared with the real test suite) shows up as items and
  sub menus. `setUp`/`tearDown`/`setUpAll`/`tearDownAll` in that body are
  ignored. For a whole app built that way, `mainFlutterUiTest` from the
  `dev_flutter_test` package (its `test_ui.dart`) does the same mapping with
  `dev_test` declarations; see the `dev-flutter-test-setup` skill.
* The menu itself is platform agnostic: keep the declaration in a shared
  library importing only `package:tekartik_test_menu/test.dart`, and have the
  Flutter entry point (this package) and a console entry point
  (`tekartik_test_menu_io`) call it. See the `tekartik-test-menu-tests` and
  `tekartik-test-menu-io-setup` skills.
* Items catch what they throw: an exception or a `fail()` is printed in the
  console and the menu stays usable, so a run never kills the app.

## Examples

### Minimal menu app

```dart
// lib/test_main.dart — flutter run -t lib/test_main.dart
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenuFlutter(() {
    item('hello', () {
      write('Hello');
    });
    item('ask something', () async {
      var answer = await prompt('Your name');
      writeln('Hello $answer');
    });
    menu('slow stuff', () {
      enter(() => writeln('entering'));
      leave(() => writeln('leaving'));
      item('wait 2s', () async {
        write('before');
        await Future<void>.delayed(const Duration(seconds: 2));
        write('after');
      });
    }, cmd: 's');
  }, showConsole: true);
}
```

### Manual test suite with test/group/expect

```dart
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenuFlutter(() {
    group('parsing', () {
      test('int', () {
        expect(int.tryParse('12'), 12);
      });
      test('bad int', () {
        expect(int.tryParse('oops'), isNull);
      });
    });
    group('device', () {
      enterItem(() => writeln('--- before each'));
      test('needs a token', () async {
        var token = await prompt('Token');
        if (token.isEmpty) {
          fail('no token given');
        }
        expect(token, isNotEmpty);
      });
    });
  });
}
```

### Pushing a page from an item

```dart
import 'package:flutter/material.dart' hide showMenu;
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenuFlutter(() {
    item('navigate', () {
      Navigator.push(
        buildContext!,
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('test')),
            body: demoSimpleList(context),
          ),
        ),
      );
    });
    item('back', () => navigator.pop());
    item('dynamic menu', () async {
      await showMenu(() {
        item('generated', () => write('generated item'));
        item('back', () => popMenu());
      });
    });
  });
}
```

### Reusing the demo menus and a run-time menu

```dart
import 'package:tekartik_test_menu_flutter/demo/common_test_menu.dart' as common;
import 'package:tekartik_test_menu_flutter/demo/demo_test_menu_flutter.dart'
    as demo;
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  initTestMenuFlutter(showConsole: true);

  item('app item', () => write('from the app'));
  menu('demos', () {
    common.main();
    demo.main();
  });
}
```

### Running a package:test declaration inside the menu

```dart
import 'package:dev_test/dev_test.dart' as dev_test;
import 'package:tekartik_test_menu_flutter/test.dart';
import 'package:tekartik_test_menu_flutter/test_ui.dart';

/// Normally in a library shared with the real test suite, declared with
/// package:test (or dev_test/flutter_test) and used as is by `flutter test`.
void testCommon() {
  dev_test.group('common', () {
    dev_test.test('expect', () {
      dev_test.expect(1, 1);
    });
  });
}

void main() {
  mainMenuFlutter(() {
    item('run the shared tests', () {
      // group/test of the body become a sub menu and its items.
      testUiFlutterMain(testCommon);
    });
  }, showConsole: true);
}
```
