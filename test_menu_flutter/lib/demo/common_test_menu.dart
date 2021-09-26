import 'package:tekartik_common_utils/async_utils.dart';
import 'package:tekartik_test_menu/test.dart';

//import 'package:tekartik_test_menu/src/common.dart';
// basic '0;-'
void main() {
  menu('common', () {
    item('write hola', () {
      write('Hola');
    });
    item('write lorem lipsum', () {
      write(
          'Sed gravida iaculis lectus, vel suscipit turpis malesuada sit amet. In maximus rutrum libero, eu porta nulla vehicula eu. Donec vel dictum neque, vitae aliquet velit. Fusce nec orci non diam dignissim tristique non sed est. Quisque venenatis a orci et venenatis.\n'
          'Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.');
    });
    item('prompt', () async {
      write('RESULT prompt: ${await prompt()}');
    });
    item('print hi', () {
      print('hi'); // ignore: avoid_print
    });
    item('crash', () {
      throw 'crash';
    });
    menu('sub', () {
      menu('below', () {
        item('write below', () => write('below sub'));
      });
      item('write sub', () => write('sub'));
    });
    item('write 250 lines', () {
      for (var i = 1; i <= 250; i++) {
        write('$i: this is a line, but only 100 of them will be displayed');
      }
    });

    group('group', () {
      test('test fail', () {
        fail('failure');
      });
      test('sleep 1000', () async {
        write('before sleep');
        await sleep(1000);
        write('after sleep 1000');
      });
      test('test success', () {
        expect(true, isTrue);
      });
    });
    menu('slow_sub', () {
      enter(() async {
        write('enter sub');
        await sleep(1000);
        write('enter sub done');
      });
      leave(() async {
        write('leave sub');
        await sleep(1000);
        write('leave sub done');
      });
      item('write hi', () {
        write('hi from slow_sub');
      });
    });

    menu('more', () {
      item('default_prompt', () async {
        write('RESULT prompt: ${await prompt()}');
      });
      item('prompt_with_text', () async {
        write('RESULT prompt: ${await prompt('Some explanation text')}');
      });
      item('sleep 1000', () async {
        write('before sleep');
        await sleep(2000);
        write('after sleep 2000');
      });
    });
  });
}
