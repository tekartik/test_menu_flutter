// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:test_api/hooks.dart' show TestFailure;
import 'package:test_api/src/backend/compiler.dart';
import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/invoker.dart';
import 'package:test_api/src/backend/live_test.dart';
import 'package:test_api/src/backend/operating_system.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/suite.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_api/src/backend/test.dart';

import 'test_menu_manager_flutter.dart' show item, mainMenuFlutter, menu, write;

/// Captures the `package:test` (or flutter_test `test`/`group`) tests that
/// [body] declares, unchanged, and shows them in the Flutter test menu: a
/// menu per group, an item per test, `run all` in every menu, `rerun last`,
/// `rerun failed` and `reset` at the root.
///
/// The tests run with test_api (`expect`, `addTearDown`, timeouts, `skip`,
/// `testOn`), a group's `setUpAll` runs once per session (before the first
/// test that needs it), its `tearDownAll` on `reset`. [extra] declares more
/// menu items after the tests.
///
/// ```dart
/// Future<void> main() => mainDevTestMenuFlutter(() => all.run(context));
/// ```
Future<void> mainDevTestMenuFlutter(
  FutureOr<void> Function() body, {
  bool? showConsole,
  void Function()? extra,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  var tree = await loadDevTestMenu(body);
  mainMenuFlutter(() {
    devTestMenu(tree);
    extra?.call();
  }, showConsole: showConsole);
}

/// The platform the tests are filtered for (`testOn`, `onPlatform`): the VM
/// with the current OS, Chrome (dart2js or dart2wasm) on the web.
SuitePlatform devTestMenuPlatform() {
  if (kIsWeb) {
    return SuitePlatform(
      Runtime.chrome,
      compiler: kIsWasm ? Compiler.dart2wasm : Compiler.dart2js,
    );
  }
  var os = switch (defaultTargetPlatform) {
    TargetPlatform.android => OperatingSystem.android,
    TargetPlatform.iOS => OperatingSystem.iOS,
    TargetPlatform.linux => OperatingSystem.linux,
    TargetPlatform.macOS => OperatingSystem.macOS,
    TargetPlatform.windows => OperatingSystem.windows,
    TargetPlatform.fuchsia => OperatingSystem.none,
  };
  return SuitePlatform(Runtime.vm, os: os);
}

/// Declares the tests of [body] in a test_api declarer (awaited, an async
/// `main` works) and builds the tree for [platform] (the current one by
/// default).
Future<DevTestMenuTree> loadDevTestMenu(
  FutureOr<void> Function() body, {
  SuitePlatform? platform,
  void Function(String line)? output,
}) async {
  var declarer = Declarer();
  await declarer.declare(() async => await body());
  platform ??= devTestMenuPlatform();
  var root = declarer.build().forPlatform(platform) ?? Group.root([]);
  return DevTestMenuTree._(
    root,
    DevTestMenuRunner._(Suite(root, platform), output ?? write),
  );
}

/// Declares the menus and items of [tree] in the current menu.
void devTestMenu(DevTestMenuTree tree) {
  var runner = tree.runner;
  _declareGroup(runner, tree.root, [tree.root]);
  item(
    'rerun last',
    () => runner._runItem(runner.lastRun, label: 'rerun last'),
    cmd: 'r',
  );
  item(
    'rerun failed',
    () => runner._runItem(runner.lastFailed, label: 'rerun failed'),
    cmd: 'f',
  );
  item('reset (run the tearDownAll, setUpAll again)', runner.reset);
}

/// A test and its groups, the root first, its parent last.
class DevTestMenuEntry {
  /// The test.
  final Test test;

  /// The groups, the root first, the parent of [test] last.
  final List<Group> groups;

  DevTestMenuEntry._(this.test, this.groups);

  /// Full name (the group names and the test name).
  String get name => test.name;

  @override
  String toString() => name;
}

/// The tests declared, filtered for the platform.
class DevTestMenuTree {
  /// The root group.
  final Group root;

  /// Runs the tests, keeps the session hooks.
  final DevTestMenuRunner runner;

  DevTestMenuTree._(this.root, this.runner);

  /// All the tests, in declaration order.
  List<DevTestMenuEntry> get entries => _groupEntries(root, [root]);
}

/// The counts of a run.
class DevTestMenuRunResult {
  /// Passed.
  var passed = 0;

  /// Skipped.
  var skipped = 0;

  /// Failed.
  var failed = 0;

  /// No failure.
  bool get success => failed == 0;

  @override
  String toString() => '+$passed ~$skipped -$failed';
}

/// Thrown by a menu item whose run had a failure, so that the menu marks it
/// as failed (the details are in the output).
class DevTestMenuFailure implements Exception {
  /// The counts of the run.
  final DevTestMenuRunResult result;

  /// Thrown by a menu item whose run had a failure.
  DevTestMenuFailure(this.result);

  @override
  String toString() => 'tests failed $result';
}

enum _Outcome { passed, skipped, failed }

/// Runs tests one at a time, a group's setUpAll once per session.
class DevTestMenuRunner {
  /// The suite the tests are loaded in.
  final Suite suite;
  final void Function(String line) _output;
  final _setUpAllDone = <Group>{};
  final _tearDownAlls = <(Test, List<Group>)>[];
  var _lastRun = <DevTestMenuEntry>[];
  var _lastFailed = <DevTestMenuEntry>[];

  DevTestMenuRunner._(this.suite, this._output);

  /// The tests of the last run.
  List<DevTestMenuEntry> get lastRun => List.of(_lastRun);

  /// The tests that failed in the last run.
  List<DevTestMenuEntry> get lastFailed => List.of(_lastFailed);

  /// Runs [entries] in order, one line per test and a summary, as
  /// `dart test` does.
  Future<DevTestMenuRunResult> run(
    List<DevTestMenuEntry> entries, {
    String? label,
  }) async {
    var result = DevTestMenuRunResult();
    var failed = <DevTestMenuEntry>[];
    var stopwatch = Stopwatch()..start();
    // Without Invoker.guard a failing expect is an unhandled exception.
    await Invoker.guard<Future<void>>(() async {
      for (var entry in entries) {
        var outcome = await _runEntry(entry);
        switch (outcome) {
          case _Outcome.passed:
            result.passed++;
          case _Outcome.skipped:
            result.skipped++;
          case _Outcome.failed:
            result.failed++;
            failed.add(entry);
        }
        var suffix = switch (outcome) {
          _Outcome.failed => ' [E]',
          _Outcome.skipped => ' (skipped)',
          _Outcome.passed => '',
        };
        _output('$result: ${entry.name}$suffix');
      }
    });
    _lastRun = List.of(entries);
    _lastFailed = failed;
    var title = result.success ? 'All tests passed' : 'Some tests failed';
    _output(
      '$result: $title'
      '${label == null ? '' : ' ($label)'}'
      ' in ${stopwatch.elapsedMilliseconds} ms',
    );
    return result;
  }

  /// A menu item run: throws [DevTestMenuFailure] (without a stack trace)
  /// when a test failed.
  Future<void> _runItem(List<DevTestMenuEntry> entries, {String? label}) async {
    var result = await run(entries, label: label);
    if (!result.success) {
      Error.throwWithStackTrace(DevTestMenuFailure(result), StackTrace.empty);
    }
  }

  /// Runs the pending tearDownAll (innermost first), the next run runs the
  /// setUpAll again.
  Future<void> reset() async {
    var tearDownAlls = _tearDownAlls.reversed.toList();
    _tearDownAlls.clear();
    _setUpAllDone.clear();
    await Invoker.guard<Future<void>>(() async {
      for (var (tearDownAll, groups) in tearDownAlls) {
        await _runLive(tearDownAll.load(suite, groups: groups));
      }
    });
    _output('reset: ${tearDownAlls.length} tearDownAll run');
  }

  Future<_Outcome> _runEntry(DevTestMenuEntry entry) async {
    var metadata = entry.test.metadata;
    if (metadata.skip) {
      if (metadata.skipReason != null) {
        _output('| skip: ${metadata.skipReason}');
      }
      return _Outcome.skipped;
    }
    // The setUpAll chain, outermost first, once per session.
    for (var i = 0; i < entry.groups.length; i++) {
      var group = entry.groups[i];
      if (_setUpAllDone.contains(group)) {
        continue;
      }
      var groups = entry.groups.sublist(0, i + 1);
      var setUpAll = group.setUpAll;
      if (setUpAll != null &&
          !await _runLive(setUpAll.load(suite, groups: groups))) {
        // Not remembered, the next run tries again.
        _output('! setUpAll failed: ${group.name}');
        return _Outcome.failed;
      }
      _setUpAllDone.add(group);
      var tearDownAll = group.tearDownAll;
      if (tearDownAll != null) {
        _tearDownAlls.add((tearDownAll, groups));
      }
    }
    var liveTest = entry.test.load(suite, groups: entry.groups);
    if (!await _runLive(liveTest)) {
      return _Outcome.failed;
    }
    return liveTest.state.result == Result.skipped
        ? _Outcome.skipped
        : _Outcome.passed;
  }

  Future<bool> _runLive(LiveTest liveTest) async {
    var subscriptions = [
      liveTest.onMessage.listen((message) => _output('| ${message.text}')),
      liveTest.onError.listen((error) {
        var text = error.error is TestFailure
            ? '${error.error}'
            : '${error.error}\n${_shortStack(error.stackTrace)}';
        _output('! $text');
      }),
    ];
    await liveTest.run();
    for (var subscription in subscriptions) {
      await subscription.cancel();
    }
    await liveTest.close();
    return liveTest.state.result.isPassing;
  }
}

String _shortStack(StackTrace stackTrace) =>
    stackTrace.toString().split('\n').take(8).join('\n');

/// The tests of [group] (whose groups are [groups]), in declaration order.
List<DevTestMenuEntry> _groupEntries(Group group, List<Group> groups) => [
  for (var entry in group.entries)
    if (entry is Group)
      ..._groupEntries(entry, [...groups, entry])
    else if (entry is Test)
      DevTestMenuEntry._(entry, groups),
];

/// [name] without the name of its parent [parentName] (test_api names are
/// full paths).
String _localName(String name, String parentName) {
  if (parentName.isNotEmpty && name.startsWith('$parentName ')) {
    return name.substring(parentName.length + 1);
  }
  return name;
}

void _declareGroup(DevTestMenuRunner runner, Group group, List<Group> groups) {
  var entries = _groupEntries(group, groups);
  item(
    'run all (${entries.length})',
    () => runner._runItem(
      entries,
      label: group.name.isEmpty ? 'all' : group.name,
    ),
    cmd: 'a',
  );
  for (var entry in group.entries) {
    if (entry is Group) {
      var subGroups = [...groups, entry];
      var count = _groupEntries(entry, subGroups).length;
      menu(
        '${_localName(entry.name, group.name)} ($count)',
        () => _declareGroup(runner, entry, subGroups),
      );
    } else if (entry is Test) {
      var metadata = entry.metadata;
      var skip = metadata.skip
          ? ' (skip${metadata.skipReason == null ? '' : ': ${metadata.skipReason}'})'
          : '';
      var testEntry = DevTestMenuEntry._(entry, groups);
      item(
        '${_localName(entry.name, group.name)}$skip',
        () => runner._runItem([testEntry]),
      );
    }
  }
}
