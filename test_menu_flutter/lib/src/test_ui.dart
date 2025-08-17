// ignore_for_file: implementation_imports

import 'package:tekartik_test_menu_flutter/test.dart' as impl;
import 'package:test_api/backend.dart';
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

class DeclarerUi implements Declarer {
  @override
  void addTearDownAll(Object? Function() callback) {
    _log('addTearDownAll');
  }

  @override
  Group build() {
    _log('build');
    throw UnimplementedError();
  }

  @override
  T declare<T>(T Function() body) {
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
    impl.group(name, body, solo: solo);
  }

  @override
  void setUp(Object? Function() callback, {TestLocation? location}) {
    _log('setUp');
  }

  @override
  void setUpAll(Object? Function() callback, {TestLocation? location}) {
    _log('setUpAll');
  }

  @override
  void tearDown(Object? Function() callback, {TestLocation? location}) {
    _log('tearDown');
  }

  @override
  void tearDownAll(Object? Function() callback, {TestLocation? location}) {
    _log('tearDownAll');
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
    // ignore: deprecated_member_use
    impl.test(name, body, solo: solo);
  }
}

/// Run a test in the flutter main zone.
Future<void> testUiFlutterMain(void Function() body) async {
  //debugDeclareUi = devWarning(true);
  var declarerUi = DeclarerUi();
  runZoned(() {
    body();
  }, zoneValues: {#test.declarer: declarerUi});
}
