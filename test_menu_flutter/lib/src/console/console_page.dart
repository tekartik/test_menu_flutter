// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tekartik_test_menu/src/test_menu/test_menu.dart';

import 'console.dart';
import 'console_theme.dart';

/// Below this width the window is full bleed.
const _framedMinWidth = 560.0;

/// From this width the menu is a sidebar, below it is under the output.
const _sidebarMinWidth = 900.0;

/// Items offered on the keypad.
const _maxKeyCount = 10;

const _commandPlaceholder = 'Item # or command (? help)';

TextStyle _mono(
  BuildContext context, {
  Color? color,
  double fontSize = 13.5,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
}) {
  // From the theme, the default text style above the scaffold has the
  // debug yellow underline.
  return Theme.of(context).textTheme.bodyMedium!.copyWith(
    color: color ?? TestMenuColors.of(context).text,
    fontSize: fontSize,
    height: 1.55,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );
}

/// The test menu console page.
class TestMenuConsolePage extends StatelessWidget {
  /// The test menu console page.
  const TestMenuConsolePage({
    super.key,
    required this.console,
    this.title = 'test menu',
  });

  /// State and actions.
  final TestMenuConsole console;

  /// Title bar text.
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: console,
      builder: (context, _) {
        final brightness = switch (console.themeMode) {
          ThemeMode.dark => Brightness.dark,
          ThemeMode.light => Brightness.light,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        return Theme(
          data: testMenuConsoleThemeData(brightness),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) {
                return;
              }
              if (console.canPop) {
                await console.pop();
              } else {
                // Root, leave the app.
                await SystemNavigator.pop();
              }
            },
            child: _ConsoleScaffold(console: console, title: title),
          ),
        );
      },
    );
  }
}

class _ConsoleScaffold extends StatelessWidget {
  const _ConsoleScaffold({required this.console, required this.title});

  final TestMenuConsole console;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: DefaultTextStyle.merge(
        style: _mono(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final framed = constraints.maxWidth >= _framedMinWidth;
            final window = _ConsoleWindow(
              console: console,
              title: title,
              framed: framed,
            );
            if (!framed) {
              return ColoredBox(
                color: colors.surface,
                child: SafeArea(child: window),
              );
            }
            return CustomPaint(
              painter: _DotsPainter(colors.dot),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.5
                                    : 0.15,
                              ),
                              blurRadius: 60,
                              spreadRadius: -24,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: window,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 8.0; y < size.height; y += 16) {
      for (var x = 8.0; x < size.width; x += 16) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => oldDelegate.color != color;
}

class _ConsoleWindow extends StatelessWidget {
  const _ConsoleWindow({
    required this.console,
    required this.title,
    required this.framed,
  });

  final TestMenuConsole console;
  final String title;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TitleBar(console: console, title: title, dots: framed),
        if (console.settingsOpen) _SettingsBar(console: console),
        _Crumbs(console: console),
        if (console.recents.isNotEmpty) _Recents(console: console),
        Expanded(child: _MainArea(console: console)),
        _Footer(console: console),
      ],
    );
  }
}

BoxDecoration _barDecoration(
  TestMenuColors colors, {
  bool top = false,
  Color? color,
}) {
  final side = BorderSide(color: colors.border);
  return BoxDecoration(
    color: color,
    border: top ? Border(top: side) : Border(bottom: side),
  );
}

//
// Title bar
//

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.console,
    required this.title,
    required this.dots,
  });

  final TestMenuConsole console;
  final String title;
  final bool dots;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final brightness = Theme.of(context).brightness;
    final menuShown = !console.layout.menuHidden;
    return Container(
      decoration: _barDecoration(colors, color: colors.surface2),
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      child: Row(
        children: [
          if (dots) ...[
            for (final color in const [
              Color(0xffff5f57),
              Color(0xfffebc2e),
              Color(0xff28c840),
            ])
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 4),
          ],
          if (console.canPop)
            _IconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: console.pop,
            ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _mono(context, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _StatusChip(status: console.status),
              ],
            ),
          ),
          _IconButton(
            icon: Icons.play_arrow,
            tooltip: 'Run the tests of this menu',
            onPressed: console.runTests,
          ),
          _IconButton(
            icon: Icons.list,
            tooltip: menuShown ? 'Hide menu' : 'Show menu',
            active: menuShown,
            onPressed: () =>
                console.layout = console.layout.copyWith(menuHidden: menuShown),
          ),
          _IconButton(
            icon: Icons.tune,
            tooltip: 'Menu layout',
            active: console.settingsOpen,
            onPressed: console.toggleSettings,
          ),
          _IconButton(
            icon: Icons.delete_outline,
            tooltip: 'Clear output',
            onPressed: console.clearOutput,
          ),
          _IconButton(
            icon: brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            tooltip: brightness == Brightness.dark
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            onPressed: () => console.toggleTheme(brightness),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    return IconButton(
      icon: Icon(icon),
      iconSize: 18,
      tooltip: tooltip,
      onPressed: onPressed,
      color: active ? colors.accent : colors.muted,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        hoverColor: colors.surface3,
      ),
    );
  }
}

class _StatusChip extends StatefulWidget {
  const _StatusChip({required this.status});

  final TestMenuStatus status;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
    lowerBound: 0.2,
  );

  bool get _animated =>
      widget.status == TestMenuStatus.running ||
      widget.status == TestMenuStatus.input;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePulse();
  }

  @override
  void didUpdateWidget(_StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse();
  }

  void _updatePulse() {
    if (_animated && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) {
        unawaited(_pulse.repeat(reverse: true));
      }
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final (color, label) = switch (widget.status) {
      TestMenuStatus.ready => (colors.green, 'READY'),
      TestMenuStatus.running => (colors.amber, 'RUNNING'),
      TestMenuStatus.input => (colors.accent, 'INPUT'),
      TestMenuStatus.error => (colors.red, 'ERROR'),
    };
    return Semantics(
      liveRegion: true,
      label: 'Status $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _pulse,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: Text(
                label,
                style: _mono(
                  context,
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// Settings
//

class _SettingsBar extends StatelessWidget {
  const _SettingsBar({required this.console});

  final TestMenuConsole console;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final layout = console.layout;
    final menuShown = !layout.menuHidden;
    final sizeEnabled = menuShown && layout.limitHeight;
    void update(TestMenuLayout layout) => console.layout = layout;

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: double.infinity,
        decoration: _barDecoration(colors, color: colors.surface2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Wrap(
          spacing: 14,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _Label('MENU'),
            _Check(
              label: 'show',
              value: menuShown,
              onChanged: (value) => update(layout.copyWith(menuHidden: !value)),
            ),
            _Check(
              label: 'limit height to',
              value: layout.limitHeight,
              enabled: menuShown,
              onChanged: (value) => update(layout.copyWith(limitHeight: value)),
            ),
            _Field(
              enabled: sizeEnabled,
              children: [
                _NumberField(
                  label: 'Menu height percent',
                  value: layout.heightPercent,
                  min: TestMenuLayout.heightPercentMin,
                  max: TestMenuLayout.heightPercentMax,
                  enabled: sizeEnabled,
                  onChanged: (value) =>
                      update(console.layout.copyWith(heightPercent: value)),
                ),
                const Text('% of height'),
              ],
            ),
            _Field(
              enabled: sizeEnabled,
              children: [
                const Text('min'),
                _NumberField(
                  label: 'Menu min height',
                  value: layout.minHeight,
                  min: 0,
                  max: TestMenuLayout.pixelsMax,
                  enabled: sizeEnabled,
                  onChanged: (value) =>
                      update(console.layout.copyWith(minHeight: value)),
                ),
                const Text('px'),
              ],
            ),
            _Field(
              enabled: sizeEnabled,
              children: [
                const Text('max'),
                _NumberField(
                  label: 'Menu max height',
                  value: layout.maxHeight,
                  min: 0,
                  max: TestMenuLayout.pixelsMax,
                  enabled: sizeEnabled,
                  onChanged: (value) =>
                      update(console.layout.copyWith(maxHeight: value)),
                ),
                const Text('px'),
              ],
            ),
            _Chip(
              tooltip: 'Reset the menu layout',
              onPressed: console.resetLayout,
              children: const [Text('reset')],
            ),
            const _Label('OUTPUT'),
            _Check(
              label: 'show',
              value: console.outputVisible,
              onChanged: (value) => console.outputVisible = value,
            ),
            if (constraints.maxWidth >= _sidebarMinWidth)
              Text(
                'The height limit applies when the menu is below the output',
                style: _mono(context, color: colors.faint, fontSize: 11.5),
              ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _mono(
        context,
        color: TestMenuColors.of(context).faint,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.children, this.enabled = true});

  final List<Widget> children;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DefaultTextStyle.merge(
        style: _mono(
          context,
          color: TestMenuColors.of(context).muted,
          fontSize: 12.5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: children,
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: enabled ? () => onChanged(!value) : null,
        child: _Field(
          enabled: enabled,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: enabled ? (value) => onChanged(value!) : null,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(text: '${widget.value}');
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Show back the value in use once done.
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = '${widget.value}';
      }
    });
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _controller.text != '${widget.value}') {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: color),
    );
    return SizedBox(
      width: 64,
      child: Semantics(
        label: widget.label,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: _mono(context, fontSize: 12.5),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            filled: true,
            fillColor: colors.surface,
            border: border(colors.border),
            enabledBorder: border(colors.border),
            disabledBorder: border(colors.border),
            focusedBorder: border(colors.accent),
          ),
          // Applied while typing, invalid values are ignored.
          onChanged: (text) {
            final value = int.tryParse(text);
            if (value != null && value >= widget.min && value <= widget.max) {
              widget.onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.children,
    required this.onPressed,
    required this.tooltip,
  });

  final List<Widget> children;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface3,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: DefaultTextStyle.merge(
              style: _mono(context, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Row(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

//
// Breadcrumb and recent items
//

/// `> _root_ > main`, the parent menus clickable if [console] is given.
List<Widget> _menuPath(
  BuildContext context,
  List<TestMenu> stack, {
  TestMenuConsole? console,
  double fontSize = 12.5,
}) {
  final colors = TestMenuColors.of(context);
  final widgets = <Widget>[];
  for (var i = 0; i < stack.length; i++) {
    final depth = i;
    final last = i == stack.length - 1;
    final name = stack[i].name;
    widgets.add(
      Text(
        '>',
        style: _mono(
          context,
          color: colors.accent,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final style = _mono(
      context,
      color: last ? colors.green : colors.text,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
    if (console == null || last) {
      widgets.add(Text(name, style: style));
    } else {
      widgets.add(
        Tooltip(
          message: 'Back to $name',
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => console.popTo(depth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(name, style: style),
            ),
          ),
        ),
      );
    }
  }
  return widgets;
}

class _Crumbs extends StatelessWidget {
  const _Crumbs({required this.console});

  final TestMenuConsole console;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final stack = console.displayedMenu == null
        ? const <TestMenu>[]
        : console.stackMenus;
    return Container(
      width: double.infinity,
      decoration: _barDecoration(colors),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Semantics(
        container: true,
        label: 'Menu path',
        child: Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _menuPath(context, stack, console: console),
        ),
      ),
    );
  }
}

class _Recents extends StatelessWidget {
  const _Recents({required this.console});

  final TestMenuConsole console;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    return Container(
      height: 36,
      decoration: _barDecoration(colors),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        children: [
          const Center(child: _Label('RECENT')),
          for (final item in console.recents) ...[
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: _Chip(
                tooltip: 'Run ${console.itemPath(item)}',
                onPressed: () => console.runRecent(item),
                children: [
                  Text(
                    console.itemKey(item),
                    style: _mono(
                      context,
                      color: colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Flexible(child: Text(' ${item.name}')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//
// Main area: output and menu
//

class _MainArea extends StatelessWidget {
  const _MainArea({required this.console});

  final TestMenuConsole console;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final layout = console.layout;
    final outputVisible = console.outputVisible;
    // Never hide both.
    final menuVisible = !layout.menuHidden || !outputVisible;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!outputVisible) {
          return _MenuView(console: console);
        }
        if (!menuVisible) {
          return _OutputView(console: console);
        }
        if (constraints.maxWidth >= _sidebarMinWidth) {
          final width = (constraints.maxWidth * 0.3).clamp(260.0, 340.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: width,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: colors.border)),
                ),
                child: _MenuView(console: console),
              ),
              Expanded(child: _OutputView(console: console)),
            ],
          );
        }
        if (layout.limitHeight) {
          return Column(
            children: [
              Expanded(child: _OutputView(console: console)),
              Container(
                constraints: BoxConstraints(
                  maxHeight: layout.menuMaxHeight(constraints.maxHeight),
                ),
                decoration: _barDecoration(colors, top: true),
                child: _MenuView(console: console, shrinkWrap: true),
              ),
            ],
          );
        }
        // Single scroll, the menu below the output.
        return _OutputView(
          console: console,
          trailing: _MenuView(console: console, embedded: true),
        );
      },
    );
  }
}

class _OutputView extends StatefulWidget {
  const _OutputView({required this.console, this.trailing});

  final TestMenuConsole console;

  /// The menu, when in the same scroll view.
  final Widget? trailing;

  @override
  State<_OutputView> createState() => _OutputViewState();
}

class _OutputViewState extends State<_OutputView> {
  final _controller = ScrollController();
  late var _followVersion = widget.console.followVersion;
  late var _menuVersion = widget.console.menuVersion;

  @override
  void initState() {
    super.initState();
    widget.console.addListener(_onConsoleChanged);
  }

  @override
  void didUpdateWidget(_OutputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.console != widget.console) {
      oldWidget.console.removeListener(_onConsoleChanged);
      widget.console.addListener(_onConsoleChanged);
    }
  }

  @override
  void dispose() {
    widget.console.removeListener(_onConsoleChanged);
    _controller.dispose();
    super.dispose();
  }

  /// The list is reversed, its end is at offset 0 and stays there while
  /// entries are added, only a forced follow needs to scroll.
  void _onConsoleChanged() {
    final console = widget.console;
    var follow = console.followVersion != _followVersion;
    _followVersion = console.followVersion;
    if (widget.trailing != null && console.menuVersion != _menuVersion) {
      follow = true;
    }
    _menuVersion = console.menuVersion;
    if (follow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients && _controller.offset != 0) {
          _controller.jumpTo(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.console.entries;
    final trailing = widget.trailing;
    final extra = trailing == null ? 0 : 1;
    final count = entries.length + extra;
    Widget list = ListView.builder(
      controller: _controller,
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      itemCount: count,
      itemBuilder: (context, index) {
        if (trailing != null && index == 0) {
          return SelectionContainer.disabled(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: trailing,
            ),
          );
        }
        final entryIndex = entries.length - 1 - (index - extra);
        final entry = entries[entryIndex];
        return _OutputEntryView(
          key: ObjectKey(entry),
          entry: entry,
          first: entryIndex == 0,
        );
      },
    );
    if (entries.isEmpty) {
      final placeholder = Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Text(
          'Output appears here. Pick an item, or type its number below.',
          style: _mono(
            context,
            color: TestMenuColors.of(context).faint,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
      if (trailing == null) {
        return Align(alignment: Alignment.topLeft, child: placeholder);
      }
      list = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          placeholder,
          Flexible(child: list),
        ],
      );
    }
    return Semantics(
      container: true,
      label: 'Output',
      child: SelectionArea(
        child: Align(alignment: Alignment.topCenter, child: list),
      ),
    );
  }
}

class _OutputEntryView extends StatefulWidget {
  const _OutputEntryView({super.key, required this.entry, required this.first});

  final TestMenuOutputEntry entry;
  final bool first;

  @override
  State<_OutputEntryView> createState() => _OutputEntryViewState();
}

class _OutputEntryViewState extends State<_OutputEntryView> {
  var _stackTraceOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final entry = widget.entry;
    final Widget child;
    switch (entry.kind) {
      case TestMenuOutputKind.line:
        child = Text(entry.text);
      case TestMenuOutputKind.info:
        child = Text(entry.text, style: _mono(context, color: colors.muted));
      case TestMenuOutputKind.command:
        child = Padding(
          padding: EdgeInsets.only(top: widget.first ? 0 : 10),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '❯  ',
                  style: TextStyle(color: colors.accent),
                ),
                TextSpan(text: entry.text),
              ],
            ),
            style: _mono(context, color: colors.muted),
          ),
        );
      case TestMenuOutputKind.error:
        final stackTrace = entry.stackTrace;
        child = Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.fromLTRB(10, 3, 6, 3),
          decoration: BoxDecoration(
            color: colors.red.withValues(alpha: 0.08),
            border: Border(left: BorderSide(color: colors.red, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(entry.text, style: _mono(context, color: colors.red)),
              if (stackTrace != null) ...[
                SelectionContainer.disabled(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _stackTraceOpen = !_stackTraceOpen),
                    child: Text(
                      '${_stackTraceOpen ? '▾' : '▸'} stack trace',
                      style: _mono(context, color: colors.muted, fontSize: 12),
                    ),
                  ),
                ),
                if (_stackTraceOpen)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      stackTrace,
                      style: _mono(context, color: colors.muted, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
        );
      case TestMenuOutputKind.prompt:
        final answer = entry.answer;
        child = Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface2,
            border: Border.all(
              color: entry.waiting ? colors.amber : colors.border,
            ),
            borderRadius: BorderRadius.circular(7),
            boxShadow: entry.waiting
                ? [
                    BoxShadow(
                      color: colors.amber.withValues(alpha: 0.16),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'PROMPT ',
                      style: TextStyle(
                        color: colors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: entry.text),
                  ],
                ),
              ),
              if (answer != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '↳  ',
                        style: TextStyle(color: colors.faint),
                      ),
                      TextSpan(text: answer.isEmpty ? '(empty)' : answer),
                    ],
                  ),
                  style: _mono(context, color: colors.green),
                ),
            ],
          ),
        );
    }
    return child;
  }
}

class _MenuView extends StatelessWidget {
  const _MenuView({
    required this.console,
    this.shrinkWrap = false,
    this.embedded = false,
  });

  final TestMenuConsole console;

  /// Natural height (limited by its parent).
  final bool shrinkWrap;

  /// Inside the output scroll view, not scrollable.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final menu = console.displayedMenu;
    if (menu == null) {
      return const SizedBox.shrink();
    }
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _menuPath(context, console.stackMenus, fontSize: 15),
        ),
      ),
      if (console.canPop)
        _MenuRow(
          keyText: '-',
          name: 'exit',
          color: colors.red,
          onTap: console.pop,
        ),
      for (var i = 0; i < menu.length; i++) _itemRow(context, menu[i], i),
      if (menu.length == 0)
        Text('Empty menu', style: _mono(context, color: colors.muted)),
    ];
    final content = Semantics(
      container: true,
      label: 'Menu',
      child: embedded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            )
          : ListView(
              key: ObjectKey(menu),
              shrinkWrap: shrinkWrap,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
              children: rows,
            ),
    );
    return content;
  }

  Widget _itemRow(BuildContext context, TestItem item, int index) {
    final colors = TestMenuColors.of(context);
    final isMenu = item is MenuTestItem;
    final isGroup = isMenu && item.menu.group == true;
    final isTest = item is RunnableTestItem && item.test == true;
    final state = console.itemState(item);
    return _MenuRow(
      keyText: item.cmd ?? '$index',
      name: item.name,
      color: isMenu ? colors.purple : null,
      submenu: isMenu,
      tag: isTest ? 'test' : (isGroup ? 'group' : null),
      running: console.isRunning(item),
      state: state,
      onTap: () => console.runItem(item),
      onPlay: isGroup ? () => console.runGroup(item) : null,
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.keyText,
    required this.name,
    required this.onTap,
    this.color,
    this.submenu = false,
    this.tag,
    this.running = false,
    this.state = TestMenuItemState.idle,
    this.onPlay,
  });

  final String keyText;
  final String name;
  final VoidCallback onTap;
  final Color? color;
  final bool submenu;
  final String? tag;
  final bool running;
  final TestMenuItemState state;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final keyColor = running
        ? colors.amber
        : submenu
        ? colors.accent
        : color ?? colors.accent;
    final mark = switch (state) {
      TestMenuItemState.idle => null,
      TestMenuItemState.running => SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.amber),
      ),
      TestMenuItemState.success => Icon(
        Icons.check,
        size: 16,
        color: colors.green,
        semanticLabel: 'success',
      ),
      TestMenuItemState.failure => Icon(
        Icons.close,
        size: 16,
        color: colors.red,
        semanticLabel: 'failure',
      ),
    };
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: running ? colors.amber.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  keyText,
                  textAlign: TextAlign.right,
                  style: _mono(
                    context,
                    color: keyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: name),
                      if (submenu)
                        TextSpan(
                          text: ' ›',
                          style: TextStyle(color: colors.faint),
                        ),
                    ],
                  ),
                  style: _mono(context, color: color),
                ),
              ),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag!.toUpperCase(),
                    style: _mono(
                      context,
                      color: colors.faint,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ?mark,
              if (onPlay != null)
                _IconButton(
                  icon: Icons.play_arrow,
                  tooltip: 'Run all the tests of $name',
                  onPressed: onPlay!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// Footer: keypad and command line
//

class _Footer extends StatefulWidget {
  const _Footer({required this.console});

  final TestMenuConsole console;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  var _prompting = false;

  /// Only grab the focus when it does not pop up a virtual keyboard.
  bool get _hasPhysicalKeyboard => switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => false,
    _ => true,
  };

  @override
  void didUpdateWidget(_Footer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prompting = widget.console.prompting;
    if (prompting && !_prompting) {
      _focusNode.requestFocus();
    }
    _prompting = prompting;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final line = _controller.text;
    _controller.clear();
    unawaited(widget.console.processLine(line));
    _focusNode.requestFocus();
  }

  void _history(int delta) {
    final text = widget.console.historyMove(delta, _controller.text);
    if (text != null) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final console = widget.console;
    final menu = console.displayedMenu;
    final prompting = console.prompting;
    final lineColor = prompting ? colors.amber : colors.accent;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
    final keys = <Widget>[
      if (menu != null)
        for (var i = 0; i < menu.length && i < _maxKeyCount; i++)
          _Key(
            text: menu[i].cmd ?? '$i',
            tooltip: menu[i].name,
            onPressed: () => console.runItem(menu[i]),
          ),
      if (console.canPop)
        _Key(
          text: '-',
          tooltip: 'exit',
          color: colors.red,
          onPressed: console.pop,
        ),
    ];
    return Container(
      decoration: _barDecoration(colors, top: true, color: colors.surface2),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final key in keys)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: key,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _Key(
                icon: Icons.keyboard_arrow_up,
                tooltip: 'Previous command',
                onPressed: () => _history(-1),
              ),
              const SizedBox(width: 6),
              _Key(
                icon: Icons.keyboard_arrow_down,
                tooltip: 'Next command',
                onPressed: () => _history(1),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              Text(
                '>',
                style: _mono(
                  context,
                  color: lineColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                        _history(-1),
                    const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                        _history(1),
                    const SingleActivator(LogicalKeyboardKey.escape): () {
                      _controller.clear();
                      console.historyReset();
                    },
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: _hasPhysicalKeyboard,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.send,
                    style: _mono(context, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: console.promptMessage ?? _commandPlaceholder,
                      hintStyle: _mono(
                        context,
                        color: colors.faint,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: colors.surface,
                      enabledBorder: border(
                        prompting ? colors.amber : colors.border,
                      ),
                      focusedBorder: border(lineColor),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 38,
                child: IconButton.filled(
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  tooltip: 'Run',
                  onPressed: _submit,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.text,
    this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final String? text;
  final IconData? icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = TestMenuColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(color: colors.border),
    );
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface3,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 18, color: colors.text)
                : Text(
                    text!,
                    style: _mono(
                      context,
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
