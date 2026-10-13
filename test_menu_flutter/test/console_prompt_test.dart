import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu_flutter/src/console/console.dart';

void main() {
  test('prompts are answered in order', () async {
    final console = TestMenuConsole(prefs: PrefsMemory());
    String? first;
    String? second;
    final firstDone = console.prompt('first?').then((value) => first = value);
    final secondDone = console
        .prompt('second?')
        .then((value) => second = value);
    await pumpEventQueue();
    expect(console.promptMessage, 'first?');

    await console.processLine('1');
    await pumpEventQueue();
    expect(first, '1');
    expect(second, isNull);
    expect(console.promptMessage, 'second?');

    await console.processLine('2');
    await Future.wait([firstDone, secondDone]);
    expect(second, '2');
    expect(console.prompting, isFalse);
  });
}
