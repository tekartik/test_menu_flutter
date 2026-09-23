import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu_flutter/src/console/console.dart';
import 'package:tekartik_test_menu_flutter/src/test_menu_manager_flutter.dart';
import 'package:tekartik_test_menu_flutter/test.dart' as tm;

const _prefsMenuKey = 'tekartik_test_menu/menu';
const _prefsThemeKey = 'tekartik_test_menu/theme';

Finder _tooltip(String message) => find.byTooltip(message);

void main() {
  group('layout', () {
    test('menuMaxHeight', () {
      const layout = TestMenuLayout();
      expect(layout.menuMaxHeight(500), 200); // 40%
      expect(layout.menuMaxHeight(100), 120); // min
      expect(layout.menuMaxHeight(2000), 480); // max
      // min wins over max, as css clamp()
      expect(
        layout.copyWith(minHeight: 300, maxHeight: 100).menuMaxHeight(500),
        300,
      );
    });
    test('map', () {
      const layout = TestMenuLayout(
        menuHidden: true,
        limitHeight: false,
        heightPercent: 50,
        minHeight: 10,
        maxHeight: 900,
      );
      expect(TestMenuLayout.fromMap(layout.toMap()), layout);
      expect(TestMenuLayout.fromMap(const {}), const TestMenuLayout());
      expect(
        TestMenuLayout.fromMap(const {'percent': 1, 'min': -1, 'max': 'no'}),
        const TestMenuLayout(),
      );
    });
  });

  test('loadPrefs', () async {
    final prefs = PrefsMemory();
    await prefs.setString(_prefsThemeKey, 'dark');
    await prefs.setMap(_prefsMenuKey, {'hidden': true, 'percent': 60});
    final console = TestMenuConsole(prefs: prefs);
    await console.loadPrefs();
    expect(console.themeMode, ThemeMode.dark);
    expect(
      console.layout,
      const TestMenuLayout(menuHidden: true, heightPercent: 60),
    );

    console.resetLayout();
    await pumpEventQueue();
    expect(await prefs.getMap(_prefsMenuKey), isNull);
  });

  testWidgets('console', (tester) async {
    final prefs = PrefsMemory();
    final console = initTestMenuFlutterConsole(prefs: prefs);
    tm.menu('main', () {
      tm.item('write hi', () => tm.write('hi'));
      tm.item('ask', () async {
        tm.write('got ${await tm.prompt('Name?')}');
      });
      tm.item('shortcut', () => tm.write('short'), cmd: 's');
      tm.item('crash', () => throw StateError('crash'));
      tm.group('tests', () {
        tm.test('ok', () {});
        tm.test('ko', () => tm.fail('ko'));
      });
    });
    // Narrow screen: the menu is below the output, height limited.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Before the auto run microtask.
    await tm.testMenuRun();
    await tester.pumpWidget(const TestMenuApp());

    expect(find.text('READY'), findsOneWidget);
    expect(find.text('main ›'), findsOneWidget);
    expect(
      find.text('Output appears here. Pick an item, or type its number below.'),
      findsOneWidget,
    );

    await console.processLine('0');
    await tester.pump();
    expect(find.text('write hi'), findsOneWidget);
    expect(find.text('exit'), findsOneWidget);

    await console.processLine('0');
    await console.processLine('s');
    await tester.pump();
    expect(find.text('❯  main › 0 write hi'), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
    expect(find.text('short'), findsOneWidget);
    // Recent chips
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text(' shortcut'), findsOneWidget);

    // A pending prompt is answered by the command line.
    final ask = console.processLine('1');
    await tester.pump();
    expect(find.text('INPUT'), findsOneWidget);
    expect(find.text('PROMPT Name?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await ask;
    await tester.pump();
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('↳  Alex'), findsOneWidget);
    expect(find.text('got Alex'), findsOneWidget);

    // Error, stack trace collapsed.
    await console.processLine('3');
    await tester.pump();
    expect(find.text('ERROR'), findsOneWidget);
    expect(find.text('ERROR CAUGHT Bad state: crash'), findsOneWidget);
    expect(find.text('▸ stack trace'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await console.processLine('unknown');
    await tester.pump();
    expect(find.text('Unknown command "unknown", type ? for help'), findsOne);

    // Group tests run when entered.
    await console.processLine('4');
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.text('ok'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    await console.processLine('-');
    await tester.pump();
    expect(find.byTooltip('Run all the tests of tests'), findsOneWidget);

    // Hide/show the menu, saved.
    await tester.tap(_tooltip('Hide menu'));
    await tester.pump();
    expect(find.text('write hi'), findsNothing);
    expect((await prefs.getMap(_prefsMenuKey))?['hidden'], isTrue);
    await tester.tap(_tooltip('Show menu'));
    await tester.pump();
    expect(find.text('write hi'), findsOneWidget);

    // Settings, percent applied while typing.
    await tester.tap(_tooltip('Menu layout'));
    await tester.pump();
    expect(find.text('% of height'), findsOneWidget);
    await tester.enterText(
      find.bySemanticsLabel('Menu height percent').last,
      '30',
    );
    await tester.pump();
    expect(console.layout.heightPercent, 30);
    expect((await prefs.getMap(_prefsMenuKey))?['percent'], 30);
    await tester.tap(find.text('reset'));
    await tester.pump();
    expect(console.layout, const TestMenuLayout());

    // Theme, saved.
    await tester.tap(_tooltip('Switch to dark theme'));
    await tester.pump();
    expect(console.themeMode, ThemeMode.dark);
    expect(await prefs.getString(_prefsThemeKey), 'dark');
    expect(_tooltip('Switch to light theme'), findsOneWidget);

    // Wide screen: the menu is a sidebar.
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    expect(find.text('write hi'), findsOneWidget);
    expect(
      find.text('The height limit applies when the menu is below the output'),
      findsOneWidget,
    );

    await console.processLine('-');
    await tester.pump();
    expect(find.text('main ›'), findsOneWidget);

    console.clearOutput();
    await tester.pump();
    expect(find.text('hi'), findsNothing);
  });
}
