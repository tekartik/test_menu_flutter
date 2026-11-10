import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu_flutter/src/test_menu_manager_flutter.dart';
import 'package:tekartik_test_menu_flutter/test.dart' as tm;
import 'package:tekartik_test_menu_flutter/test_ui.dart';
import 'package:test_api/scaffolding.dart' as scaffolding;

void main() {
  testWidgets(
    'testUiFlutterMain runs the setUp/tearDown of the parent groups',
    (tester) async {
      final console = initTestMenuFlutterConsole(prefs: PrefsMemory());
      final log = <String>[];
      await testUiFlutterMain(() {
        scaffolding.setUp(() => log.add('root setUp'));
        scaffolding.group('outer', () {
          scaffolding.setUp(() => log.add('outer setUp'));
          scaffolding.tearDown(() => log.add('outer tearDown 1'));
          scaffolding.tearDown(() => log.add('outer tearDown 2'));
          scaffolding.test('o', () => log.add('o'));
          scaffolding.group('inner', () {
            scaffolding.setUp(() => log.add('inner setUp'));
            scaffolding.tearDown(() => log.add('inner tearDown'));
            scaffolding.test('t', () => log.add('t'));
          });
        });
      });
      await tm.testMenuRun();
      await tester.pumpWidget(const TestMenuApp());
      Future<void> line(String line) async {
        await console.processLine(line);
        for (var i = 0; i < 5; i++) {
          await tester.pump();
        }
      }

      // Entering a group runs its tests, as package:test runs them: the setUps
      // of the root and of every parent group first, the tearDowns inner first,
      // each group's in reverse order.
      await line('0');
      expect(log, [
        'root setUp',
        'outer setUp',
        'o',
        'outer tearDown 2',
        'outer tearDown 1',
      ]);
      log.clear();
      await line('1');
      expect(log, [
        'root setUp',
        'outer setUp',
        'inner setUp',
        't',
        'inner tearDown',
        'outer tearDown 2',
        'outer tearDown 1',
      ]);
    },
  );
}
