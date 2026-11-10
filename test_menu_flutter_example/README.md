# test_menu_flutter_example

Entry points showing
[tekartik_test_menu_flutter](../test_menu_flutter) menus. Run one with
`flutter run -t <file>` (a device, `-d chrome`, `-d linux`...):

| Entry point | Shows |
|---|---|
| `lib/main.dart` | items, sub menus, errors, a long task, navigation (`buildContext`) |
| `lib/dev_test_menu_main.dart` | unchanged `package:test`/dev_test tests as a menu (`mainDevTestMenuFlutter`): run one, a group, all, rerun the failed ones |
| `lib/test_main.dart` | `test`/`group` of `package:tekartik_test_menu_flutter/test.dart` (items and sub menus) |
| `lib/with_failure_test_main.dart` | failing tests |
| `lib/main_solo_item.dart`, `lib/main_solo_item_sub.dart`, `lib/solo_menu_main.dart`, `lib/solo_test_main.dart` | `solo_item`, `solo_menu`, `solo_test` (dev only) |
| `lib/no_hot_reload_main.dart` | `initTestMenuFlutter` then the declarations |
| `demo/test_menu.dart` | the common demo menu on the console (`dart run demo/test_menu.dart`, arguments are typed lines: `0 0 . .`) |

The `testCommon` entries of `lib/main.dart` and `lib/test_main.dart` declare
shared dev_test tests outside `mainDevTestMenuFlutter`: they do not work in
the app (an empty menu, `expect` failing with `OutsideTestException`); use
`lib/dev_test_menu_main.dart` for shared tests.

Dependency, in your own app:

```yaml
dependencies:
  tekartik_test_menu_flutter:
    git:
      url: https://github.com/tekartik/test_menu_flutter
      path: test_menu_flutter
    version: '>=1.3.0'
```
