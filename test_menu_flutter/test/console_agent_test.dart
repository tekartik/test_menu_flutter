import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Size;
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu/test_menu_agent.dart';
import 'package:tekartik_test_menu_flutter/src/test_menu_manager_flutter.dart';
import 'package:tekartik_test_menu_flutter/test.dart' as tm;

List<String> _items(Map<String, Object?> state) => [
  for (final item in (state['items'] as List).cast<Map>())
    '${item['key']} ${item['name']}${item['menu'] == true ? ' >' : ''}',
];

List<String> _output(Map<String, Object?> state) =>
    (state['output'] as List).cast<String>();

void main() {
  testWidgets('driven by the menu agent', (tester) async {
    initTestMenuFlutterConsole(prefs: PrefsMemory());
    tm.menu('main', () {
      tm.item('write hi', () => tm.write('hi'));
      tm.item('ask', () async {
        tm.write('got ${await tm.prompt('Name?')}');
      });
      tm.item('shortcut', () => tm.write('short'), cmd: 's');
      tm.command((line) => throw StateError('bad $line'));
    });
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tm.testMenuRun();
    await tester.pumpWidget(const TestMenuApp());

    // The agent waits on real timers.
    Future<Map<String, Object?>> run(
      String name, [
      Map<String, Object?>? args,
    ]) async {
      final value = (await tester.runAsync(() => menuAgent.run(name, args)))!;
      expect(value['ok'], isTrue, reason: '$value');
      await tester.pump();
      return (value['result'] as Map).cast<String, Object?>();
    }

    expect(
      [for (final c in menuAgent.describe()) c['name']],
      ['menu', 'menu_line'],
    );

    var state = await run('menu');
    expect(_items(state), ['0 main >']);
    expect(state['status'], 'ready');

    state = await run('menu_line', {'line': '0'});
    expect(state['path'], ['main']);
    expect(_items(state), ['0 write hi', '1 ask', 's shortcut']);
    // The screen follows.
    expect(find.text('write hi'), findsOneWidget);

    state = await run('menu_line', {'line': '0'});
    expect(_output(state), ['hi']);
    expect(find.text('hi'), findsOneWidget);

    state = await run('menu_line', {'line': 's'});
    expect(_output(state), ['short']);

    // A prompt, answered by the next line, on the screen too.
    state = await run('menu_line', {'line': '1'});
    expect(state['status'], 'input');
    expect(state['prompt'], 'Name?');
    expect(_output(state), ['PROMPT Name?']);
    expect(find.text('INPUT'), findsOneWidget);
    state = await run('menu_line', {'line': 'Alex'});
    expect(state['status'], 'ready');
    expect(_output(state), ['ANSWER Alex', 'got Alex']);
    expect(find.text('↳  Alex'), findsOneWidget);
    expect(find.bySemanticsLabel('Status READY'), findsOneWidget);

    // The command handler error, recorded once.
    state = await run('menu_line', {'line': 'boom'});
    final output = _output(state);
    expect(output, hasLength(1));
    expect(output.single, startsWith('ERROR Bad state: bad boom'));

    state = await run('menu_line', {'line': '-'});
    expect(state['path'], isEmpty);
    expect(find.text('write hi'), findsNothing);

    final error = (await tester.runAsync(
      () => menuAgent.run('menu_line', {'line': '-'}),
    ))!;
    expect(error['ok'], isFalse);
    expect(error['error'], contains('top menu'));
  });
}
