// ignore_for_file: implementation_imports

import 'package:tekartik_test_menu_flutter/test.dart' as impl;
// Only what all the test_api versions export (0.7.14 adds Declarer and Group,
// which would make the src imports below unnecessary there, not before).
import 'package:test_api/backend.dart' show TestLocation;
import 'package:test_api/src/backend/configuration/timeout.dart';
import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/group.dart';

import 'import.dart';

var debugDeclareUi = false;
void _log(Object? message) {
  if (debugDeclareUi) {
    // ignore: avoid_print
    print(message);
  }
}

/// True if a `skip` parameter skips (a reason or true).
bool _isSkipped(Object? skip) => skip != null && skip != false;

/// The `setUp` and `tearDown` callbacks of a group (or of the root).
class _Scope {
  final setUps = <Object? Function()>[];
  final tearDowns = <Object? Function()>[];
}

/// Calls [callback], awaiting it when it returns a future.
Future<void> _call(Object? Function() callback) async {
  var result = callback();
  if (result is Future) {
    await result;
  }
}

/// Runs [body] the way package:test runs a test: the `setUp` callbacks of
/// [scopes] (the root first), the body, then the `tearDown` callbacks, the
/// inner group first and each group in reverse order, even after a failure.
/// The first error is thrown.
Future<void> _runTest(List<_Scope> scopes, Object? Function() body) async {
  Object? error;
  StackTrace? stackTrace;
  try {
    for (var scope in scopes) {
      for (var setUp in List.of(scope.setUps)) {
        await _call(setUp);
      }
    }
    await _call(body);
  } catch (e, st) {
    error = e;
    stackTrace = st;
  }
  for (var scope in scopes.reversed) {
    for (var tearDown in scope.tearDowns.reversed.toList()) {
      try {
        await _call(tearDown);
      } catch (e, st) {
        if (error == null) {
          error = e;
          stackTrace = st;
        }
      }
    }
  }
  if (error != null) {
    Error.throwWithStackTrace(error, stackTrace!);
  }
}

/// Declares the package:test calls as menus and items: `setUpAll` and
/// `tearDownAll` run when the group menu is entered and left, `setUp` and
/// `tearDown` around each test (those of the parent groups too, as
/// package:test runs them), skipped tests and groups are not declared.
class DeclarerUi implements Declarer {
  /// The scopes of the groups being declared, the root first.
  final _scopes = <_Scope>[_Scope()];

  @override
  void addTearDownAll(Object? Function() callback) {
    _log('addTearDownAll');
    impl.leave(callback);
  }

  @override
  Group build() {
    _log('build');
    throw UnimplementedError();
  }

  @override
  T declare<T>(T Function() body, {Map<Symbol, Object?>? zoneValues}) {
    _log('declare');
    throw UnimplementedError();
  }

  @override
  void group(
    String name,
    void Function() body, {
    TestLocation? location,
    String? testOn,
    Timeout? timeout,
    Object? skip,
    Map<String, dynamic>? onPlatform,
    Object? tags,
    int? retry,
    bool solo = false,
  }) {
    _log('group');
    if (_isSkipped(skip)) {
      _log('skip group $name');
      return;
    }
    impl.group(
      name,
      () {
        _scopes.add(_Scope());
        try {
          body();
        } finally {
          _scopes.removeLast();
        }
      },
      // ignore: invalid_use_of_do_not_submit_member
      solo: solo,
    );
  }

  /// Runs before each test of the current group and of its sub groups (not
  /// a menu `enterItem`, which only covers the items of its own menu).
  @override
  void setUp(Object? Function() callback, {TestLocation? location}) {
    _log('setUp');
    _scopes.last.setUps.add(callback);
  }

  @override
  void setUpAll(Object? Function() callback, {TestLocation? location}) {
    _log('setUpAll');
    impl.enter(callback);
  }

  /// Runs after each test of the current group and of its sub groups, the
  /// inner group first, each group in reverse order.
  @override
  void tearDown(Object? Function() callback, {TestLocation? location}) {
    _log('tearDown');
    _scopes.last.tearDowns.add(callback);
  }

  @override
  void tearDownAll(Object? Function() callback, {TestLocation? location}) {
    _log('tearDownAll');
    impl.leave(callback);
  }

  @override
  void test(
    String name,
    Object? Function() body, {
    TestLocation? location,
    String? testOn,
    Timeout? timeout,
    Object? skip,
    Map<String, dynamic>? onPlatform,
    Object? tags,
    int? retry,
    bool solo = false,
  }) {
    _log('test');
    if (_isSkipped(skip)) {
      _log('skip test $name');
      return;
    }
    // The scopes themselves: a setUp declared after the test applies too.
    var scopes = List.of(_scopes);
    // ignore: invalid_use_of_do_not_submit_member
    impl.test(name, () => _runTest(scopes, body), solo: solo);
  }
}

/// Declares the `package:test` calls of [body] in the current menu: a `group`
/// is a sub menu, a `test` an item (see [DeclarerUi]).
///
/// The test bodies run as plain menu items, without a test_api invoker: the
/// `expect` of `package:test` (or dev_test) throws an `OutsideTestException`
/// there, even when it passes, and `testOn` and timeouts are ignored. For
/// unchanged test files, prefer `mainDevTestMenuFlutter` of
/// `package:tekartik_test_menu_flutter/dev_test_menu.dart`.
Future<void> testUiFlutterMain(void Function() body) async {
  //debugDeclareUi = devWarning(true);
  var declarerUi = DeclarerUi();
  runZoned(() {
    body();
  }, zoneValues: {#test.declarer: declarerUi});
}
