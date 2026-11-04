import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu_flutter/dev_test_menu.dart';
import 'package:tekartik_test_menu_flutter/src/test_menu_manager_flutter.dart';
import 'package:tekartik_test_menu_flutter/test.dart' as tm;
import 'package:test_api/backend.dart' show Runtime, SuitePlatform;
import 'package:test_api/scaffolding.dart' as scaffolding;

/// Unchanged package:test style declarations, as in a test file.
void declareSample(List<String> log) {
  scaffolding.group('g', () {
    scaffolding.setUpAll(() => log.add('setUpAll'));
    scaffolding.tearDownAll(() => log.add('tearDownAll'));
    scaffolding.setUp(() => log.add('setUp'));
    scaffolding.test('ok', () {
      log.add('ok');
      scaffolding.addTearDown(() => log.add('addTearDown'));
      expect(1, 1);
    });
    scaffolding.test('fail', () => expect(1, 2));
    scaffolding.test('skipped', () => log.add('skipped'), skip: 'reason');
    scaffolding.test('browser', () => log.add('browser'), testOn: 'browser');
  });
  scaffolding.test('top', () async {
    await Future<void>.delayed(Duration.zero);
    log.add('top');
  });
}

void main() {
  test('load and run, setUpAll once per session', () async {
    final log = <String>[];
    final lines = <String>[];
    final tree = await loadDevTestMenu(
      () async {
        // An async main awaiting before declaring.
        await Future<void>.delayed(Duration.zero);
        declareSample(log);
      },
      platform: SuitePlatform(Runtime.vm),
      output: lines.add,
    );
    // testOn: 'browser' is filtered out on the VM.
    expect(tree.entries.map((entry) => entry.name), [
      'g ok',
      'g fail',
      'g skipped',
      'top',
    ]);

    final runner = tree.runner;
    var result = await runner.run(tree.entries);
    expect('$result', '+2 ~1 -1');
    expect(log, ['setUpAll', 'setUp', 'ok', 'addTearDown', 'setUp', 'top']);
    expect(lines, contains('+1 ~0 -1: g fail [E]'));
    expect(
      lines.where((line) => line.startsWith('! Expected: <2>')),
      hasLength(1),
    );
    expect(lines.last, startsWith('+2 ~1 -1: Some tests failed'));
    expect(runner.lastFailed.map((entry) => entry.name), ['g fail']);

    // A rerun does not run setUpAll again.
    log.clear();
    result = await runner.run(tree.entries.take(1).toList());
    expect('$result', '+1 ~0 -0');
    expect(log, ['setUp', 'ok', 'addTearDown']);

    // Reset runs tearDownAll, the next run runs setUpAll again.
    log.clear();
    await runner.reset();
    expect(log, ['tearDownAll']);
    await runner.run(runner.lastRun);
    expect(log, ['tearDownAll', 'setUpAll', 'setUp', 'ok', 'addTearDown']);
  });

  testWidgets('menu', (tester) async {
    final console = initTestMenuFlutterConsole(prefs: PrefsMemory());
    final log = <String>[];
    final tree = await tester.runAsync(
      () => loadDevTestMenu(
        () => declareSample(log),
        platform: SuitePlatform(Runtime.vm),
      ),
    );
    devTestMenu(tree!);
    await tm.testMenuRun();
    await tester.pumpWidget(const TestMenuApp());
    final root = console.displayedMenu!;
    expect(root.items.map((item) => item.name), [
      'run all (4)',
      'g (3)',
      'top',
      'rerun last',
      'rerun failed',
      'reset (run the tearDownAll, setUpAll again)',
    ]);

    // Entering a group runs nothing.
    await console.processLine('1');
    await tester.pump();
    expect(console.displayedMenu!.items.map((item) => item.name), [
      'run all (3)',
      'ok',
      'fail',
      'skipped (skip: reason)',
    ]);
    expect(log, isEmpty);

    // Run one test of the group.
    await tester.runAsync(() => console.processLine('1'));
    await tester.pump();
    expect(log, ['setUpAll', 'setUp', 'ok', 'addTearDown']);
    expect(
      console.entries.map((entry) => entry.text),
      contains(startsWith('+1 ~0 -0: All tests passed')),
    );

    // A failing test: one short error line, no stack trace.
    await tester.runAsync(() => console.processLine('2'));
    await tester.pump();
    final errors = console.entries.where(
      (entry) => entry.text.startsWith('ERROR CAUGHT'),
    );
    expect(errors.map((entry) => entry.text), [
      'ERROR CAUGHT tests failed +0 ~0 -1',
    ]);
    expect(errors.single.stackTrace, isNull);
  });
}
