## 1.3.0

- `package:tekartik_test_menu_flutter/dev_test_menu.dart`:
  `mainDevTestMenuFlutter(body)` shows unchanged `package:test` (or
  flutter_test `test`/`group`) tests in the menu, run with test_api
  (`expect`, `addTearDown`, timeouts, `skip`, `testOn`): a menu per group, an
  item per test, `run all`, `rerun last`, `rerun failed`, `reset`; a group's
  `setUpAll` runs once per session, its `tearDownAll` on reset

## 1.2.0

- The console fills the screen, as the web test menu: no window frame (no
  dotted background, no title bar dots), one header row (menu path starting
  with the title, status dot, run tests, hide menu, clear, settings), the
  theme moved to the settings, no menu title, recent items in the footer,
  keypad only shown when the menu is hidden, history buttons next to the
  command line
- An LLM agent can drive the menu (`app-agent` MCP `menu` and `menu_line`
  tools): over the VM service of a debug run, and on the web with `?agent`
- Requires dev_build 1.2.0 and tekartik_test_menu 0.8.1

## 1.1.0

- New console page, same design and features as the web test menu
  (`tekartik_test_menu_browser`): dark/light theme, status, breadcrumb,
  recent items, structured output (errors with collapsible stack trace,
  inline prompts), keypad and command line (`-` back, `?` help, history,
  menu `command` handler)
- Menu can be hidden, and its height limited (percent of height, min and max)
  when below the output; sidebar on wide screens
- Theme and menu layout saved in a `PrefsLight` (`prefs:` parameter,
  `tekartik_prefs_flutter` shared preferences by default)
- `prompt()` answered by the command line instead of a dialog
- `showConsole` now defaults to true

## 0.2.0

* Basic working for iOS and Android

## [0.0.1] - TODO: Add release date.

* TODO: Describe initial release.
