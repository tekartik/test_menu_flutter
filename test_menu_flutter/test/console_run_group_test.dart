import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu_flutter/src/test_menu_manager_flutter.dart';
import 'package:tekartik_test_menu_flutter/test.dart' as tm;

void main() {
  testWidgets('runGroup runs the group hooks', (tester) async {
    final console = initTestMenuFlutterConsole(prefs: PrefsMemory());
    final log = <String>[];
    tm.menu('main', () {
      tm.group('g', () {
        tm.enter(() => log.add('enter'));
        tm.leave(() => log.add('leave'));
        tm.enterItem(() => log.add('enterItem'));
        tm.leaveItem(() => log.add('leaveItem'));
        tm.test('t1', () => log.add('t1'));
        tm.group('sub', () {
          tm.enter(() => log.add('sub enter'));
          tm.leave(() => log.add('sub leave'));
          tm.test('t2', () => log.add('t2'));
        });
      });
    });
    await tm.testMenuRun();
    await tester.pumpWidget(const TestMenuApp());
    final main = console.displayedMenu!;
    final group = main[0];

    await console.runGroup(group);
    expect(log, [
      'enter',
      'enterItem',
      't1',
      'leaveItem',
      'sub enter',
      't2',
      'sub leave',
      'leave',
    ]);
    // The displayed menu and the stack are unchanged.
    expect(console.displayedMenu, main);
    expect(console.stackMenus.last, main);
    expect(console.entries.last.text, 'SUCCESS tests 2/2');
  });
}
