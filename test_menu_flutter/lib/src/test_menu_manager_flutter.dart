import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu/src/test_menu/test_menu.dart';
import 'package:tekartik_test_menu/src/test_menu/test_menu_manager.dart';
import 'package:tekartik_test_menu/test_menu_presenter.dart';
import 'package:tekartik_test_menu_flutter/src/component/common_import.dart';
import 'package:tekartik_test_menu_flutter/src/component/menu_items.dart';
import 'package:tekartik_test_menu_flutter/src/component/menu_page.dart';
import 'package:tekartik_test_menu_flutter/src/model/item.dart';

export 'package:tekartik_test_menu/test_menu.dart';

// set to false before checkin
bool testMenuConsoleDebug = false;

class FlutterTestMenu {
  final TestMenu testMenu;
  BuildContext buildContext;

  FlutterTestMenu(this.testMenu);

  @override
  String toString() {
    return "$testMenu $buildContext";
  }
}

Map<TestMenu, FlutterTestMenu> flutterTestMenuMap = {};

class Prompt {
  final String message;
  final Completer<String> _completer = new Completer<String>();

  Prompt(this.message);

  Future get future => _completer.future;

  @override
  String toString() {
    return "Prompt: $message";
  }
}

class _TestMenuManagerFlutter extends TestMenuPresenter
    with TestMenuPresenterMixin {
  static final String tag = "[test_menu_flutter]";

  bool verbose;
  ValueChanged<TestMenu> onTestMenuChanged = (TestMenu testMenu) {
    devPrint("unhandled $testMenu");
  };
  ValueChanged<String> onOutputChanged = (String text) {
    devPrint("unhandled output $text");
  };
  ValueChanged<Prompt> onPrompted = (Prompt prompt) {
    devPrint("unhandled onPrompted $prompt");
  };

  BuildContext buildContext;

  // void Function() bodyBuilder;

  _TestMenuManagerFlutter();

  TestMenu displayedMenu;
  bool showConsole = true;

  Map<TestItem, BaseItem> testItemItems = {};

  get navigator => Navigator.of(buildContext);

  BaseItem newTestItemBase(TestItem testItem, {bool run}) {
    BaseItem item;
    if (testItem is RunnableTestItem) {
      item = new Item(testItem, run != false);
    } else if (testItem is MenuTestItem) {
      item = new Menu(testItem, run == true);
    }
    testItemItems[testItem] = item;
    return item;
  }

  BaseItem getTestItemBase(TestItem testItem) {
    var item = testItemItems[testItem];
    return item;
  }

  Item getTestItemItem(TestItem testItem) {
    var item = testItemItems[testItem];
    if (item == null) {
      item = newTestItemBase(testItem);
    }
    return testItemItems[testItem];
  }

  Menu getTestItemMenu(TestItem testItem) {
    var item = testItemItems[testItem];
    if (item == null) {
      item = newTestItemBase(testItem);
    }
    return testItemItems[testItem];
  }

  // Get or create
  FlutterTestMenu get displayedFlutterMenu {
    return getFlutterMenu(displayedMenu);
  }

  FlutterTestMenu getFlutterMenu(TestMenu testMenu) {
    if (testMenu != null) {
      var flutterTestMenu = flutterTestMenuMap[testMenu];

      // Clean of map
      var cleanedMap = <TestMenu, FlutterTestMenu>{};
      for (var menuRunner in testMenuManager.stackMenus) {
        var testMenu = menuRunner.menu;
        if (flutterTestMenuMap.containsKey(testMenu)) {
          cleanedMap[testMenu] = flutterTestMenuMap[testMenu];
        }
      }
      flutterTestMenuMap = cleanedMap;

      if (flutterTestMenu == null) {
        flutterTestMenu = new FlutterTestMenu(testMenu);
        flutterTestMenuMap[testMenu] = flutterTestMenu;
      }

      return flutterTestMenu;
    }
    return null;
  }

//  bool done = false;

  @override
  void presentMenu(TestMenu menu) {
    onTestMenuChanged(menu);
    processMenu(menu);
  }

  _setOutput(List<String> output) {
    onOutputChanged(output.join('\n'));
  }

  void clear() {
    output.clear();
    print('clear output');
    _setOutput(output);
  }

  void show(bool show) {
    print('show console ${show}');
    showConsole = show;
    _setOutput(output);
  }

  void write(Object message) {
    print('[o] $message');
    output.add("$message");
    if (output.length > 50) {
      output = output.sublist(20);
    }
    _setOutput(output);
    // stdout.writeln("$message");
  }

  List<String> output = [];

  Future<String> prompt(Object message) async {
    devPrint('Prompt: $message');
    write(message ?? "[Enter text]");
    message ??= "Enter text";
    var prompt = new Prompt(message);
    onPrompted(prompt);
    return await prompt.future;
    /*
    var completer = new Completer<String>.sync();
    promptCompleter = completer;
    // read the next line
    _nextLine();
    return completer.future;
    */
  }
}

void initTestMenuFlutter({Widget builder(Widget child)}) {
  //TestMenuManager.debug.on = true;
  _testMenuManagerFlutter = new _TestMenuManagerFlutter();
  //_testMenuManagerFlutter.builder = builder;

  Widget app = new TestMenuApp();
  if (builder != null) {
    app = builder(app);
  }
  runApp(app);
  // set current
  testMenuPresenter = _testMenuManagerFlutter;
}

_TestMenuManagerFlutter _testMenuManagerFlutter;

void mainMenu(void body()) {
  initTestMenuFlutter(builder: (Widget child) {
    // _testMenuManagerFlutter.bodyBuilder = body;
    return Builder(builder: (BuildContext context) {
      devPrint('Building tests');
      body();
      return child;
    });
    /*
    if (builder != null) {
      app = builder(app);
    }
    runApp(app);
    body();
    */
  });
}

class TestMenuApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Test Menu',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: RootMenuPage(),
      // new MyHomePage(),
    );
  }
}

class RootMenuPage extends StatefulWidget {
  @override
  _RootMenuPageState createState() => _RootMenuPageState();
}

class _RootMenuPageState extends State<RootMenuPage> {
  TestMenu displayedMenu;
  String outputText = '[console output]';
  final promptController = TextEditingController();

  _RootMenuPageState();

  @override
  void initState() {
    devPrint('initState');
    super.initState();
    displayedMenu = _testMenuManagerFlutter.displayedMenu;
    // _testMenuManagerFlutter.displayedMenu testMenuManager.
    _testMenuManagerFlutter.onTestMenuChanged = (TestMenu testMenu) {
      setState(() {
        displayedMenu = testMenu;
      });
    };
    _testMenuManagerFlutter.onOutputChanged = (String output) {
      setState(() {
        outputText = output ?? '';
      });
    };
    _testMenuManagerFlutter.onPrompted = (Prompt prompt) {};
  }

  @override
  Widget build(BuildContext context) {
    _testMenuManagerFlutter.buildContext = context;
    _testMenuManagerFlutter.onPrompted = (Prompt prompt) {
      _showDialog() async {
        devPrint('Show prompt $prompt');
        try {
          var result = await showDialog<String>(
            context: context,
            child: new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new TextField(
                      controller: promptController,
                      autofocus: true,
                      decoration: new InputDecoration(
                          labelText: prompt.message ?? '', hintText: ''),
                    ),
                  )
                ],
              ),
              actions: <Widget>[
                new FlatButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.pop(context, null);
                    }),
                new FlatButton(
                    child: const Text('OPEN'),
                    onPressed: () {
                      Navigator.pop(context, promptController.value.text);
                    })
              ],
            ),
          );
          prompt._completer.complete(result);
        } catch (e) {
          prompt._completer.completeError(e);
        }
      }

      _showDialog();
    };
    devPrint('building root');
    /*
    if (_testMenuManagerFlutter.bodyBuilder != null) {
      _testMenuManagerFlutter.bodyBuilder();
    }
    */
    if (displayedMenu != null) {
      var menu = displayedMenu;
      devPrint('Build menu $menu');
      var children2 = <Widget>[];
      if (_testMenuManagerFlutter.showConsole) {
        children2.add(Expanded(
            flex: 3,
            child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Stack(children: <Widget>[
                  SingleChildScrollView(
                      reverse: true,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              outputText,
                              style: TextStyle(fontSize: 9.0),
                              softWrap: true,
                              overflow: TextOverflow.clip,
                            )
                          ]))
                ]))));
      }
      children2.add(Expanded(
          flex: 5,
          child: MenuItems(
              items: new List.generate(menu.items.length, (int index) {
            var testItem = menu.items[index];
            if (testItem is MenuTestItem) {
              if (true) {
                return _testMenuManagerFlutter.getTestItemMenu(testItem);
              } else {
                /*
                // return new I
                return new MainItem(testItem.name, null,
                    action: (BuildContext context) async {
                  devPrint('running $testItem');
                  await testMenuManager.runItem(testItem);
                  devPrint('done $testItem');
                });
                */
              }
            } else {
              devPrint('creating test item ${testItem}');
              /*
              return new Item(testItem.name, () async {
                    devPrint('running $testItem');
                    await testMenuManager.runItem(testItem);
                    devPrint('done $testItem');
                  });*/
              return _testMenuManagerFlutter.getTestItemItem(testItem);
              // return new Future.sync(item.run).then((_) {
              /*
        if (verbose) {
          print("$TAG done '$item'");
        }
        */
            }
          }))));
      var column = Column(children: children2);

      var actions = <Widget>[];
      bool showConsole = _testMenuManagerFlutter.showConsole;
      actions.add(IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () {
          devPrint('play');
          runTests();
        },
        tooltip: 'Clear the output console',
      ));
      if (showConsole) {
        actions.add(IconButton(
          icon: const Icon(Icons.clear_all),
          onPressed: () {
            devPrint('clear');
            _testMenuManagerFlutter.clear();
          },
          tooltip: 'Clear the output console',
        ));
        actions.add(IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            devPrint('show');
            _testMenuManagerFlutter.show(false);
          },
          tooltip: 'Hide the output console',
        ));
      } else {
        actions.add(IconButton(
          icon: const Icon(Icons.show_chart),
          onPressed: () {
            devPrint('show');
            _testMenuManagerFlutter.show(true);
          },
          tooltip: 'Show the output console',
        ));
      }

      return new WillPopScope(
          // onWillPop: () async => true,

          onWillPop: () async {
            devPrint("onWillPop ${testMenuManager.canPop()} ${testMenuManager
                .activeDepth} ${testMenuManager
                .activeMenu is RootTestMenu}");
            /*if (testMenuManager.activeMenu is RootTestMenu) {
              devPrint('atRoot');
              return true;
            }*/
            if (testMenuManager.canPop()) {
              testMenuManager.popMenu();
              return false;
            }
            if (testMenuManager.activeMenu is RootTestMenu) {
              devPrint('atRoot');
              return true;
            }
            /*
            Navigator.of(context).pop();
            testMenuManager.popMenu().then((_) {
              // Navigator.of(context).pop();
            });
            */
            return false;
          },
          child: new Scaffold(
              appBar: new AppBar(
                title: new Text(menu?.name ?? "MAIN"),
                actions: actions,
              ),
              body: column));
    }
    return new MenuPage(title: 'Test menu example');
  }

  void runTests() {
    TestMenu menu = this.displayedMenu;
    devPrint('menu $menu');
    setState(() {
      for (var testItem in menu.items) {
        // recreate the items
        _testMenuManagerFlutter.newTestItemBase(testItem, run: true);
      }
    });
  }
}

Navigator get navigator => _testMenuManagerFlutter.navigator;

BuildContext get buildContext => _testMenuManagerFlutter.buildContext;
