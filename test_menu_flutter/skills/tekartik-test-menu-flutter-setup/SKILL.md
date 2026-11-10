---
name: tekartik-test-menu-flutter-setup
description: >-
  Use when building an interactive manual test/debug menu app in Flutter with
  tekartik_test_menu_flutter: mainMenuFlutter, initTestMenuFlutter, the
  declaration API menu/item/test/group/enter/leave/enterItem/leaveItem/command/
  write/prompt/showMenu/solo_item/solo_menu/expect/fail, the buildContext and
  navigator globals to push a page from an item, showConsole, the console page
  (command line, keypad, inline prompt, menu hide/height limit, theme saved
  through a PrefsLight, prefs parameter), mainDevTestMenuFlutter from
  dev_test_menu.dart to run unchanged package:test files as a menu (and the
  older testUiFlutterMain of test_ui.dart), the demo menus (demo/demo.dart demoSimpleList, demo/common_test_menu.dart,
  demo/demo_test_menu_flutter.dart), the showMenu clash with
  package:flutter/material.dart, and driving the menu from an LLM agent
  (app-agent MCP menu and menu_line tools, VM service or ?agent on the web).
---

# Flutter test menu app (tekartik_test_menu_flutter)

`tekartik_test_menu_flutter` turns a `tekartik_test_menu` declaration into a
runnable Flutter app: a console page (same design as the web test menu of
`tekartik_test_menu_browser`) with the output log, the menu, a keypad and a
command line. It is the way to drive manual/device-only code
(plugins, auth, network, storage) by hand on a real device or emulator.

## Guidelines

* Dependency (git, not published on pub.dev):
  ```yaml
  dependencies:
    tekartik_test_menu_flutter:
      git:
        url: https://github.com/tekartik/test_menu_flutter
        path: test_menu_flutter
      version: '>=1.3.0'
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
  * `package:tekartik_test_menu_flutter/dev_test_menu.dart`:
    `mainDevTestMenuFlutter` (unchanged test files as a menu).
  * `package:tekartik_test_menu_flutter/test_ui.dart`: `testUiFlutterMain`
    (older, see below).
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
* `showConsole` (default `true`) is the initial visibility of the output log
  where `write()`/`writeln()` lands; it can be toggled in the
  settings and cleared from the header.
* The console page fills the screen (no window frame), the same design as
  the web test menu. One header row: the menu path (`test menu` for the root
  menu, a parent goes back when tapped), the status (a dot when ready,
  RUNNING, INPUT or ERROR otherwise), run the tests of the menu, hide/show
  the menu, clear, settings (theme and menu layout). Then the output log
  (item paths, `ERROR...` lines with a collapsible stack trace, prompts with
  their answer, selectable text) and the menu (item states: running,
  success, failure; play button on group menus). The footer holds the recent
  items, a keypad (only when the menu is hidden) and the command line, with
  history buttons, taking an item number or `cmd` shortcut, `-` or `.` to go
  back, `?` for help, arrow up/down for the history and any other line for
  the menu `command` handler.
* Driven by an LLM agent: `initTestMenuFlutterConsole` (so `mainMenuFlutter`
  too) calls `testMenuAgentInit` of tekartik_test_menu. The `app-agent` MCP
  server then lists the `menu` (state, output) and `menu_line {line}` (a
  line typed in the command line, prompt answers included) tools:
  * a debug run: `flutter run`, then `app_connect {vmService: <the uri
    printed>}`;
  * the web: the app url with `?agent` (a release build too, no key for a
    dev menu), `app_connect {open: <url>}`.

  The screen follows what the agent does. An app already registering its
  own agent commands (tekartik_app_agent `agentInit`) keeps them: call
  `agentInit` first.
* `prompt()` is answered inline by the command line (no dialog): the prompt
  shows in the output and the next submitted line, even empty, answers it.
* Narrow screens (< 900 px) show the menu below the output, its height
  limited by default to 40% of the area (bounded by 120 to 480 px, the menu
  then scrolls); wide screens show it as a sidebar. The theme and the menu
  layout are saved with a `PrefsLight` (`prefs:` parameter of
  `mainMenuFlutter`/`initTestMenuFlutter`), `tekartik_prefs_flutter`
  shared preferences by default, so the app gets the `shared_preferences`
  plugin.
* The tests of a `group` menu run when it is first displayed; the play
  button of a group item runs all its tests (sub groups included) and writes
  `SUCCESS tests x/y` or `ERROR tests x/y`.
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
* Unchanged `package:test` files (or flutter_test `test`/`group`, or
  dev_test): `Future<void> main() => mainDevTestMenuFlutter(my_test.main);`
  from `package:tekartik_test_menu_flutter/dev_test_menu.dart`. A menu per
  group, an item per test, `run all` in every menu, `rerun last`, `rerun
  failed` and `reset` at the root; the tests run with test_api (the real
  `expect` and matchers, `setUp`/`tearDown` of every parent group,
  `addTearDown`, timeouts, `skip`, `testOn`), a group's `setUpAll` once per
  session (`reset` runs the `tearDownAll`). `testWidgets` is not supported.
  `loadDevTestMenu`/`devTestMenu` put the same tree in your own menu.
* `testUiFlutterMain(body)` from `test_ui.dart` is the older way: `body`
  runs in a zone whose `package:test` declarer is the menu, so `test()` and
  `group()` become items and sub menus, `setUpAll`/`tearDownAll` the group's
  `enter`/`leave`, and `setUp`/`tearDown` run around each test as
  package:test runs them (those of the parent groups too); skipped tests are
  not declared, `testOn` and timeouts are ignored. The test bodies run as
  plain items, without a test_api `Invoker`: the `expect` of `package:test`
  or dev_test throws `OutsideTestException` there, even when it passes (the
  menu's own `expect` of `test.dart` works). Prefer `mainDevTestMenuFlutter`.
  `mainFlutterUiTest` of the `dev_flutter_test` package (its `test_ui.dart`)
  maps `dev_test` declarations to the menu the same way; see the
  `dev-flutter-test-setup` skill.
* The menu itself is platform agnostic: keep the declaration in a shared
  library importing only `package:tekartik_test_menu/test.dart`, and have the
  Flutter entry point (this package) and a console entry point
  (`tekartik_test_menu_io`) call it. See the `tekartik-test-menu-tests` and
  `tekartik-test-menu-io-setup` skills.
* Items catch what they throw: an exception or a `fail()` is shown as an
  error in the output, the item gets a failure mark and the menu stays
  usable, so a run never kills the app.

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

### Running unchanged package:test declarations in the menu

```dart
// lib/dev_test_menu_main.dart: flutter run -t lib/dev_test_menu_main.dart
import 'package:dev_test/test.dart';
import 'package:tekartik_test_menu_flutter/dev_test_menu.dart';

/// Normally in a library shared with the real test suite, declared with
/// package:test (or dev_test/flutter_test) and used as is by `flutter test`.
void testCommon() {
  group('common', () {
    late List<int> list;
    setUp(() => list = [1]);
    test('expect', () {
      expect(list, [1]);
    });
    test('skipped', () {}, skip: 'not on a device');
  });
}

/// One item per test, run with test_api: `run all`, `rerun failed`...
Future<void> main() => mainDevTestMenuFlutter(testCommon);
```
