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
