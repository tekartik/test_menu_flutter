// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu/src/test_menu/test_menu.dart';
import 'package:tekartik_test_menu/test_menu_presenter.dart';
import 'package:tekartik_test_menu_flutter/src/console/console.dart';
import 'package:tekartik_test_menu_flutter/src/console/console_page.dart';
import 'package:tekartik_test_menu_flutter/src/console/console_theme.dart';

import 'import.dart';

export 'package:tekartik_test_menu/test_menu.dart';

// set to false before checkin
bool testMenuConsoleDebug = false;

class _TestMenuManagerFlutter extends TestMenuPresenter
    with TestMenuPresenterMixin {
  _TestMenuManagerFlutter(this.console);

  final TestMenuConsole console;

  /// The menu page context.
  BuildContext? buildContext;

  NavigatorState get navigator => Navigator.of(buildContext!);

  @override
  void presentMenu(TestMenu menu) {
    console.presentMenu(menu);
  }

  @override
  void write(Object message) {
    writeln(message);
  }

  @override
  void writeln(Object message) {
    // ignore: avoid_print
    print('[o] $message');
    console.writeln(message);
  }

  @override
  Future<String> prompt(Object? message) => console.prompt(message);

  @override
  Future preProcessItem(TestItem item) async {
    console.preProcessItem(item);
  }
}

/// Create the console and set it as the menu presenter, without running the
/// app ([TestMenuApp] displays it).
TestMenuConsole initTestMenuFlutterConsole({
  bool? showConsole,
  PrefsLight? prefs,
}) {
  final console = TestMenuConsole(
    prefs: prefs ?? prefsFlutter,
    showOutput: showConsole ?? true,
  );
  final manager = _testMenuManagerFlutter = _TestMenuManagerFlutter(console);
  testMenuPresenter = manager;
  unawaited(console.loadPrefs());
  return console;
}

/// Run the menu app, declare the menu right after.
///
/// [builder] wraps the menu app, [showConsole] (default true) shows the
/// output, [prefs] saves the theme and the menu layout (shared preferences by
/// default).
void initTestMenuFlutter({
  Widget Function(Widget child)? builder,
  bool? showConsole,
  PrefsLight? prefs,
}) {
  // Needed by the shared preferences before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  initTestMenuFlutterConsole(showConsole: showConsole, prefs: prefs);

  Widget app = const TestMenuApp();
  if (builder != null) {
    app = builder(app);
  }
  runApp(app);
}

_TestMenuManagerFlutter? _testMenuManagerFlutter;

@Deprecated('Use mainMenuFlutter')
void mainMenu(void Function() body, {bool? showConsole}) {
  mainMenuFlutter(body, showConsole: showConsole);
}

var _mainMenuDone = false;

/// Main menu for flutter.
///
/// [showConsole] (default true) shows the output, [prefs] saves the theme and
/// the menu layout (shared preferences by default).
void mainMenuFlutter(
  void Function() body, {
  bool? showConsole,
  PrefsLight? prefs,
}) {
  initTestMenuFlutter(
    builder: (Widget child) {
      return Builder(
        builder: (_) {
          /// Needed to avoid 2 calls on restart
          if (!_mainMenuDone) {
            _mainMenuDone = true;
            body();
          }
          return child;
        },
      );
    },
    showConsole: showConsole,
    prefs: prefs,
  );
}

/// The menu app.
class TestMenuApp extends StatelessWidget {
  /// The menu app, [console] defaults to the one of [initTestMenuFlutter].
  const TestMenuApp({super.key, this.console});

  /// State and actions.
  final TestMenuConsole? console;

  @override
  Widget build(BuildContext context) {
    final console = this.console ?? _testMenuManagerFlutter!.console;
    return ListenableBuilder(
      listenable: console,
      builder: (context, _) => MaterialApp(
        title: 'Test Menu',
        theme: testMenuAppThemeData(Brightness.light),
        darkTheme: testMenuAppThemeData(Brightness.dark),
        themeMode: console.themeMode,
        home: const RootMenuPage(),
      ),
    );
  }
}

/// The menu page.
class RootMenuPage extends StatelessWidget {
  /// The menu page.
  const RootMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = _testMenuManagerFlutter!..buildContext = context;
    return TestMenuConsolePage(console: manager.console);
  }
}

NavigatorState get navigator => _testMenuManagerFlutter!.navigator;

BuildContext? get buildContext => _testMenuManagerFlutter!.buildContext;
