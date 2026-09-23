// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Brightness, ThemeMode;
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_test_menu/src/test_menu/test_menu.dart';
import 'package:tekartik_test_menu/src/test_menu/test_menu_manager.dart';

/// Output entries kept.
const _maxOutputCount = 200;

/// Recently run items offered as quick chips.
const _maxRecentCount = 8;

const _maxHistoryCount = 50;
const _exitCommands = {'-', '.'};
const _helpCommand = '?';

const _prefsThemeKey = 'tekartik_test_menu/theme';
const _prefsMenuKey = 'tekartik_test_menu/menu';

const _pathSeparator = ' › ';

/// State of an item.
enum TestMenuItemState {
  /// Not run yet.
  idle,

  /// Running.
  running,

  /// Last run succeeded.
  success,

  /// Last run failed.
  failure,
}

/// Global status.
enum TestMenuStatus {
  /// Nothing running.
  ready,

  /// An item is running.
  running,

  /// A prompt is waiting for an answer.
  input,

  /// The last run failed.
  error,
}

/// Kind of output entry.
enum TestMenuOutputKind {
  /// Written text.
  line,

  /// Item run (its path).
  command,

  /// Error, with an optional stack trace.
  error,

  /// Prompt, with its answer.
  prompt,

  /// Console information (help...).
  info,
}

/// An output entry.
class TestMenuOutputEntry {
  /// An output entry.
  TestMenuOutputEntry(this.kind, this.text, {this.stackTrace});

  /// Kind.
  final TestMenuOutputKind kind;

  /// Text (error summary for an error, message for a prompt).
  String text;

  /// Error stack trace.
  String? stackTrace;

  /// Prompt answer.
  String? answer;

  /// Prompt waiting for an answer.
  var waiting = false;

  @override
  String toString() => '$kind $text';
}

/// Menu layout, saved in the local prefs.
@immutable
class TestMenuLayout {
  /// Menu layout.
  const TestMenuLayout({
    this.menuHidden = false,
    this.limitHeight = true,
    this.heightPercent = heightPercentDefault,
    this.minHeight = minHeightDefault,
    this.maxHeight = maxHeightDefault,
  });

  /// Default height limit, in percent.
  static const heightPercentDefault = 40;

  /// Default lower bound of the height limit, in pixels.
  static const minHeightDefault = 120;

  /// Default upper bound of the height limit, in pixels.
  static const maxHeightDefault = 480;

  /// Valid percent range.
  static const heightPercentMin = 5;

  /// Valid percent range.
  static const heightPercentMax = 100;

  /// Valid pixel range (min and max height).
  static const pixelsMax = 10000;

  /// Menu hidden (the keypad and the command line remain).
  final bool menuHidden;

  /// Limit the menu height when it is below the output (narrow screens).
  final bool limitHeight;

  /// Height limit in percent of the output and menu area.
  final int heightPercent;

  /// Lower bound of the height limit, in pixels.
  final int minHeight;

  /// Upper bound of the height limit, in pixels.
  final int maxHeight;

  /// Menu max height for an [available] height, min wins over max (as css
  /// `clamp()`).
  double menuMaxHeight(double available) {
    final value = available * heightPercent / 100;
    final bounded = value > maxHeight ? maxHeight.toDouble() : value;
    return bounded < minHeight ? minHeight.toDouble() : bounded;
  }

  /// Copy with changes.
  TestMenuLayout copyWith({
    bool? menuHidden,
    bool? limitHeight,
    int? heightPercent,
    int? minHeight,
    int? maxHeight,
  }) {
    return TestMenuLayout(
      menuHidden: menuHidden ?? this.menuHidden,
      limitHeight: limitHeight ?? this.limitHeight,
      heightPercent: heightPercent ?? this.heightPercent,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }

  /// Saved map.
  Map<String, Object?> toMap() => {
    'hidden': menuHidden,
    'limit': limitHeight,
    'percent': heightPercent,
    'min': minHeight,
    'max': maxHeight,
  };

  /// From a saved map, invalid values are ignored.
  factory TestMenuLayout.fromMap(Map map) {
    int intValue(String key, int defaultValue, int min, int max) {
      final value = map[key];
      return value is int && value >= min && value <= max
          ? value
          : defaultValue;
    }

    return TestMenuLayout(
      menuHidden: map['hidden'] == true,
      limitHeight: map['limit'] != false,
      heightPercent: intValue(
        'percent',
        heightPercentDefault,
        heightPercentMin,
        heightPercentMax,
      ),
      minHeight: intValue('min', minHeightDefault, 0, pixelsMax),
      maxHeight: intValue('max', maxHeightDefault, 0, pixelsMax),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TestMenuLayout &&
      other.menuHidden == menuHidden &&
      other.limitHeight == limitHeight &&
      other.heightPercent == heightPercent &&
      other.minHeight == minHeight &&
      other.maxHeight == maxHeight;

  @override
  int get hashCode =>
      Object.hash(menuHidden, limitHeight, heightPercent, minHeight, maxHeight);

  @override
  String toString() => toMap().toString();
}

/// State and actions of the test menu console, the widgets listen to it.
class TestMenuConsole extends ChangeNotifier {
  /// [prefs] saves the theme and the menu layout, [showOutput] is the initial
  /// output visibility.
  TestMenuConsole({PrefsLight? prefs, bool showOutput = true})
    : prefs = prefs ?? PrefsMemory(),
      _outputVisible = showOutput;

  /// Theme and menu layout storage.
  final PrefsLight prefs;

  TestMenu? _displayedMenu;

  /// Displayed menu.
  TestMenu? get displayedMenu => _displayedMenu;

  /// Incremented when the displayed menu changes.
  var menuVersion = 0;

  /// Incremented when the output should scroll to its end.
  var followVersion = 0;

  final _entries = <TestMenuOutputEntry>[];

  /// Output entries.
  List<TestMenuOutputEntry> get entries => _entries;

  final _recents = <TestItem>[];

  /// Recently run items, most recent first.
  List<TestItem> get recents => _recents;

  final _history = <String>[];
  int? _historyIndex;
  var _historyDraft = '';

  final _states = <TestItem, TestMenuItemState>{};
  final _running = <TestItem>{};
  var _runningCount = 0;
  var _lastRunFailed = false;

  /// Group menus whose tests were run when first displayed.
  final _autoRunMenus = <TestMenu>{};

  Completer<String>? _promptCompleter;
  TestMenuOutputEntry? _promptEntry;

  /// Last error entry and its text, see [_fixLastError].
  (TestMenuOutputEntry, String)? _lastError;

  var _layout = const TestMenuLayout();

  /// Menu layout.
  TestMenuLayout get layout => _layout;

  var _themeMode = ThemeMode.system;

  /// Theme mode, system until toggled.
  ThemeMode get themeMode => _themeMode;

  bool _outputVisible;

  /// Output visibility.
  bool get outputVisible => _outputVisible;

  set outputVisible(bool visible) {
    _outputVisible = visible;
    notifyListeners();
  }

  var _settingsOpen = false;

  /// Menu layout settings shown.
  bool get settingsOpen => _settingsOpen;

  /// Show/hide the menu layout settings.
  void toggleSettings() {
    _settingsOpen = !_settingsOpen;
    notifyListeners();
  }

  /// Pending prompt message.
  String? get promptMessage =>
      _promptCompleter == null ? null : _promptEntry?.text;

  /// A prompt is waiting for an answer.
  bool get prompting => _promptCompleter != null;

  /// Global status.
  TestMenuStatus get status => prompting
      ? TestMenuStatus.input
      : _runningCount > 0
      ? TestMenuStatus.running
      : _lastRunFailed
      ? TestMenuStatus.error
      : TestMenuStatus.ready;

  /// State of an item (last run).
  TestMenuItemState itemState(TestItem item) =>
      _states[item] ?? TestMenuItemState.idle;

  /// True if the item is running.
  bool isRunning(TestItem item) => _running.contains(item);

  TestMenuManager get _manager => testMenuManager!;

  /// Menus of the stack, from the root.
  List<TestMenu> get stackMenus => [
    for (final runner in _manager.stackMenus) runner.menu,
  ];

  /// True if not in the root menu.
  bool get canPop => testMenuManager?.canPop() ?? false;

  void _notify() => notifyListeners();

  //
  // Presenter
  //

  /// Show a menu.
  void presentMenu(TestMenu menu) {
    _displayedMenu = menu;
    menuVersion++;
    _notify();
    if (menu.group == true && _autoRunMenus.add(menu)) {
      // Tests of a group run when it is first displayed.
      scheduleMicrotask(() => _runTests(menu, groups: false));
    }
  }

  /// Write a line, `ERROR...` lines are shown as errors.
  void writeln(Object message) {
    final text = '$message';
    if (text.startsWith('ERROR')) {
      _appendError(text);
    } else {
      _append(TestMenuOutputEntry(TestMenuOutputKind.line, text));
    }
  }

  /// Ask for a text, answered by the next line of the command line.
  Future<String> prompt(Object? message) {
    final text = '${message ?? 'Enter text'}';
    _promptEntry?.waiting = false;
    final entry = TestMenuOutputEntry(TestMenuOutputKind.prompt, text)
      ..waiting = true;
    _promptEntry = entry;
    final completer = _promptCompleter = Completer<String>();
    _append(entry, follow: true);
    return completer.future;
  }

  /// Called before an item is run.
  void preProcessItem(TestItem item) {
    _append(
      TestMenuOutputEntry(TestMenuOutputKind.command, itemPath(item)),
      follow: true,
    );
    _addRecent(item);
  }

  void _answerPrompt(String value) {
    final completer = _promptCompleter!;
    _promptCompleter = null;
    final entry = _promptEntry;
    _promptEntry = null;
    if (entry != null) {
      entry
        ..waiting = false
        ..answer = value;
    }
    _notify();
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  //
  // Output
  //

  void _append(TestMenuOutputEntry entry, {bool follow = false}) {
    _entries.add(entry);
    if (_entries.length > _maxOutputCount) {
      _entries.removeRange(0, _entries.length - _maxOutputCount);
    }
    if (follow) {
      followVersion++;
    }
    _notify();
  }

  void _info(String text) =>
      _append(TestMenuOutputEntry(TestMenuOutputKind.info, text), follow: true);

  void _appendError(String text, {bool follow = false}) {
    final newline = text.indexOf('\n');
    final entry = newline < 0
        ? TestMenuOutputEntry(TestMenuOutputKind.error, text)
        : TestMenuOutputEntry(
            TestMenuOutputKind.error,
            text.substring(0, newline),
            stackTrace: _stackTraceOrNull(text.substring(newline + 1)),
          );
    _lastError = (entry, text);
    _append(entry, follow: follow);
  }

  String? _stackTraceOrNull(String text) => text.trim().isEmpty ? null : text;

  /// The runner writes `ERROR CAUGHT $error $stackTrace` on one line, split
  /// it once the actual error is known.
  void _fixLastError(Object error) {
    final lastError = _lastError;
    final summary = 'ERROR CAUGHT $error';
    if (lastError != null && lastError.$2.startsWith('$summary ')) {
      final (entry, text) = lastError;
      entry
        ..text = summary
        ..stackTrace = _stackTraceOrNull(text.substring(summary.length + 1));
      _notify();
    }
  }

  /// Clear the output, a pending prompt stays.
  void clearOutput() {
    _entries.clear();
    final promptEntry = _promptEntry;
    if (promptEntry != null && prompting) {
      _entries.add(promptEntry);
    }
    _notify();
  }

  //
  // Items
  //

  /// Item key, its shortcut or its index.
  String itemKey(TestItem item) =>
      item.cmd ?? '${item.parent?.indexOfItem(item) ?? '?'}';

  /// `main › 0 write hola`
  String itemPath(TestItem item) {
    final names = <String>[];
    for (var menu = item.parent; menu != null; menu = menu.parent) {
      if (menu is! RootTestMenu) {
        names.insert(0, menu.name);
      }
    }
    return [...names, '${itemKey(item)} ${item.name}'].join(_pathSeparator);
  }

  void _addRecent(TestItem item) {
    _recents
      ..remove(item)
      ..insert(0, item);
    if (_recents.length > _maxRecentCount) {
      _recents.removeLast();
    }
  }

  /// Run an action, tracking the running state and swallowing its error
  /// (the menu runner already wrote it unless [reportError] is set).
  Future<bool> _guard(
    Future<void> Function() action, {
    TestItem? item,
    bool reportError = false,
  }) async {
    final runnable = item is RunnableTestItem;
    _runningCount++;
    _lastRunFailed = false;
    if (item != null) {
      _running.add(item);
      if (runnable) {
        _states[item] = TestMenuItemState.running;
      }
    }
    _notify();
    var success = false;
    try {
      await action();
      success = true;
    } catch (e, st) {
      _lastRunFailed = true;
      _fixLastError(e);
      if (reportError) {
        _appendError('ERROR $e\n$st', follow: true);
      }
    } finally {
      _runningCount--;
      if (item != null) {
        _running.remove(item);
        if (runnable) {
          _states[item] = success
              ? TestMenuItemState.success
              : TestMenuItemState.failure;
        }
      }
      _notify();
    }
    return success;
  }

  /// Run an item (or enter a menu).
  Future<void> runItem(TestItem item) async {
    await _guard(() => _manager.runItem(item), item: item);
  }

  /// Go back to the parent menu.
  Future<void> pop() async {
    if (!canPop) {
      _info('Already in the top menu');
      return;
    }
    await _guard(() => _manager.popMenu());
  }

  /// Pop until the menu at [depth] of the stack is active.
  Future<void> popTo(int depth) async {
    while (_manager.activeDepth > depth) {
      final before = _manager.activeDepth;
      await pop();
      if (_manager.activeDepth >= before) {
        break;
      }
    }
  }

  /// Pop and push menus until [target] is active, false if not reachable
  /// (a dynamic menu that was closed).
  Future<bool> _navigateTo(TestMenu target) async {
    final manager = _manager;
    final chain = <TestMenu>[];
    for (TestMenu? menu = target; menu != null; menu = menu.parent) {
      chain.insert(0, menu);
    }
    var common = chain.length - 1;
    while (common >= 0 && !manager.stackContainsMenu(chain[common])) {
      common--;
    }
    if (common < 0) {
      return false;
    }
    while (manager.activeMenu != chain[common]) {
      if (!await manager.popMenu()) {
        return false;
      }
    }
    for (var i = common + 1; i < chain.length; i++) {
      await manager.pushMenu(chain[i]);
    }
    return manager.activeMenu == target;
  }

  /// Run a recent item, from any menu.
  Future<void> runRecent(TestItem item) async {
    final parent = item.parent;
    if (parent != null && await _navigateTo(parent)) {
      await runItem(item);
    } else {
      _recents.remove(item);
      _info('"${item.name}" is no longer available');
    }
  }

  /// Run all the tests of a group menu item.
  Future<void> runGroup(TestItem menuItem) async {
    if (menuItem is! MenuTestItem) {
      return;
    }
    _append(
      TestMenuOutputEntry(
        TestMenuOutputKind.command,
        '${itemPath(menuItem)} (all tests)',
      ),
      follow: true,
    );
    var count = 0;
    var successCount = 0;
    Future<void> runMenu(TestMenu menu) async {
      for (final item in menu.items) {
        if (item is MenuTestItem) {
          await runMenu(item.menu);
        } else if (item is RunnableTestItem) {
          count++;
          final success = await _guard(() async {
            try {
              final result = item.fn();
              if (result is Future) {
                await result;
              }
            } catch (e) {
              writeln('ERROR ${item.name}: $e');
              rethrow;
            }
          }, item: item);
          if (success) {
            successCount++;
          }
        }
      }
    }

    _running.add(menuItem);
    _states[menuItem] = TestMenuItemState.running;
    _notify();
    try {
      await runMenu(menuItem.menu);
    } finally {
      _running.remove(menuItem);
    }
    final success = successCount == count;
    _states[menuItem] = success
        ? TestMenuItemState.success
        : TestMenuItemState.failure;
    _lastRunFailed = !success;
    writeln('${success ? 'SUCCESS' : 'ERROR'} tests $successCount/$count');
  }

  /// Run the tests of the displayed menu (test items and groups).
  Future<void> runTests() async {
    final menu = _displayedMenu;
    if (menu != null) {
      await _runTests(menu, groups: true);
    }
  }

  Future<void> _runTests(TestMenu menu, {required bool groups}) async {
    var found = false;
    for (final item in menu.items) {
      if (item is RunnableTestItem && item.test == true) {
        found = true;
        await runItem(item);
      } else if (groups && item is MenuTestItem && item.menu.group == true) {
        found = true;
        await runGroup(item);
      }
    }
    if (!found && groups) {
      _info('No test in this menu');
    }
  }

  //
  // Command line
  //

  /// Process a line typed in the command line.
  ///
  /// It answers the pending prompt if any. Otherwise it is an item number or
  /// shortcut, `-` (or `.`) to go back, `?` for help, anything else going to
  /// the menu `command` handler if declared.
  Future<void> processLine(String line) async {
    if (prompting) {
      _answerPrompt(line);
      return;
    }
    line = line.trim();
    if (line.isEmpty) {
      return;
    }
    _addHistory(line);
    final menu = _displayedMenu;
    if (menu == null) {
      return;
    }
    if (_exitCommands.contains(line)) {
      await pop();
      return;
    }
    if (line == _helpCommand) {
      _writeHelp(menu);
      return;
    }
    final item = menu.byCmd(line);
    if (item != null) {
      await runItem(item);
      return;
    }
    final command = menu.command;
    if (command != null) {
      _append(
        TestMenuOutputEntry(TestMenuOutputKind.command, line),
        follow: true,
      );
      await _guard(() async {
        final result = command.fn(line);
        if (result is Future) {
          await result;
        }
      }, reportError: true);
      return;
    }
    _append(
      TestMenuOutputEntry(
        TestMenuOutputKind.error,
        'Unknown command "$line", type ? for help',
      ),
      follow: true,
    );
  }

  void _writeHelp(TestMenu menu) {
    final lines = <String>[];
    for (var i = 0; i < menu.length; i++) {
      final item = menu[i];
      lines.add('${(item.cmd ?? '$i').padLeft(3)}  ${item.name}');
    }
    if (canPop) {
      lines.add('  -  exit (or .)');
    }
    lines
      ..add('  ?  this help')
      ..add(' ↑↓  previous commands');
    _info(lines.join('\n'));
  }

  void _addHistory(String line) {
    _historyIndex = null;
    if (_history.isEmpty || _history.last != line) {
      _history.add(line);
      if (_history.length > _maxHistoryCount) {
        _history.removeAt(0);
      }
    }
  }

  /// Browse the history from the [current] text, null if unchanged.
  String? historyMove(int delta, String current) {
    if (_history.isEmpty) {
      return null;
    }
    var index = _historyIndex;
    if (index == null) {
      if (delta > 0) {
        return null;
      }
      _historyDraft = current;
      index = _history.length;
    }
    index += delta;
    if (index < 0) {
      index = 0;
    }
    if (index >= _history.length) {
      _historyIndex = null;
      return _historyDraft;
    }
    _historyIndex = index;
    return _history[index];
  }

  /// Forget the history position (the line was edited or cleared).
  void historyReset() {
    _historyIndex = null;
  }

  //
  // Settings
  //

  /// Change the menu layout, saved in [prefs].
  set layout(TestMenuLayout layout) {
    if (layout == _layout) {
      return;
    }
    _layout = layout;
    _notify();
    _savePrefs(() => prefs.setMap(_prefsMenuKey, layout.toMap()));
  }

  /// Back to the default layout.
  void resetLayout() {
    _layout = const TestMenuLayout();
    _notify();
    _savePrefs(() => prefs.remove(_prefsMenuKey));
  }

  /// Switch between light and dark from the [current] brightness.
  void toggleTheme(Brightness current) {
    final dark = current != Brightness.dark;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    _notify();
    _savePrefs(() => prefs.setString(_prefsThemeKey, dark ? 'dark' : 'light'));
  }

  /// Load the theme and the menu layout from [prefs].
  Future<void> loadPrefs() async {
    try {
      final theme = await prefs.getString(_prefsThemeKey);
      if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (theme == 'light') {
        _themeMode = ThemeMode.light;
      }
      final menu = await prefs.getMap(_prefsMenuKey);
      if (menu != null) {
        _layout = TestMenuLayout.fromMap(menu);
      }
      _notify();
    } catch (e) {
      debugPrint('test menu prefs error $e');
    }
  }

  void _savePrefs(Future<void> Function() action) {
    unawaited(
      Future.sync(action).catchError((Object e) {
        debugPrint('test menu prefs error $e');
      }),
    );
  }
}
