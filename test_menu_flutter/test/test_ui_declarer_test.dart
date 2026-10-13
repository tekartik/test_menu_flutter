import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu_flutter/src/test_menu_manager_flutter.dart';
import 'package:tekartik_test_menu_flutter/test.dart' as tm;
import 'package:tekartik_test_menu_flutter/test_ui.dart';
import 'package:test_api/scaffolding.dart' as scaffolding;

void main() {
  testWidgets('testUiFlutterMain setUp/tearDown and skip', (tester) async {
    final console = initTestMenuFlutterConsole(prefs: PrefsMemory());
    final log = <String>[];
    await testUiFlutterMain(() {
      scaffolding.group('g', () {
        scaffolding.setUpAll(() => log.add('setUpAll'));
        scaffolding.tearDownAll(() => log.add('tearDownAll'));
        scaffolding.setUp(() => log.add('setUp'));
        scaffolding.tearDown(() => log.add('tearDown'));
        scaffolding.test('t', () => log.add('t'));
        scaffolding.test('skipped', () => log.add('skipped'), skip: true);
      });
      scaffolding.group('skipped group', () {
        scaffolding.test('t2', () => log.add('t2'));
      }, skip: 'reason');
    });
    await tm.testMenuRun();
    await tester.pumpWidget(const TestMenuApp());
    final root = console.displayedMenu!;
    expect(root.items.map((item) => item.name), ['g']);

    // Entering the group runs its tests.
    await console.processLine('0');
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(console.displayedMenu!.items.map((item) => item.name), ['t']);
    expect(log, ['setUpAll', 'setUp', 't', 'tearDown']);

    await console.processLine('-');
    await tester.pump();
    expect(log, ['setUpAll', 'setUp', 't', 'tearDown', 'tearDownAll']);
  });
}
