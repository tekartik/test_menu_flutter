import 'package:flutter/material.dart';

/// Monospace fonts, the first available one is used.
const _monospaceFallback = <String>[
  'JetBrains Mono',
  'Cascadia Mono',
  'SF Mono',
  'Menlo',
  'Consolas',
  'DejaVu Sans Mono',
  'Liberation Mono',
  'Roboto Mono',
  'Courier New',
];

/// Colors of the test menu console, same tokens as the web console.
@immutable
class TestMenuColors extends ThemeExtension<TestMenuColors> {
  /// Colors of the test menu console.
  const TestMenuColors({
    required this.background,
    required this.dot,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.green,
    required this.red,
    required this.amber,
    required this.purple,
  });

  /// Dark colors.
  static const dark = TestMenuColors(
    background: Color(0xff0b0f14),
    dot: Color(0x12ffffff),
    surface: Color(0xff0f141a),
    surface2: Color(0xff141a22),
    surface3: Color(0xff1b232e),
    border: Color(0xff27303c),
    text: Color(0xffd7dee7),
    muted: Color(0xff8b96a5),
    faint: Color(0xff5d6776),
    accent: Color(0xff22c1dc),
    onAccent: Color(0xff041a1f),
    green: Color(0xff3fca7a),
    red: Color(0xfff47067),
    amber: Color(0xffe3b341),
    purple: Color(0xffb392f0),
  );

  /// Light colors.
  static const light = TestMenuColors(
    background: Color(0xffeef1f5),
    dot: Color(0x170f172a),
    surface: Color(0xffffffff),
    surface2: Color(0xfff6f8fa),
    surface3: Color(0xffeaeef2),
    border: Color(0xffd0d7de),
    text: Color(0xff1f2328),
    muted: Color(0xff59636e),
    faint: Color(0xff8c959f),
    accent: Color(0xff0a7ea4),
    onAccent: Color(0xffffffff),
    green: Color(0xff1a7f37),
    red: Color(0xffcf222e),
    amber: Color(0xff9a6700),
    purple: Color(0xff8250df),
  );

  /// Page background.
  final Color background;

  /// Background dots.
  final Color dot;

  /// Window background.
  final Color surface;

  /// Bars background.
  final Color surface2;

  /// Buttons and hover background.
  final Color surface3;

  /// Borders.
  final Color border;

  /// Text.
  final Color text;

  /// Secondary text.
  final Color muted;

  /// Hints.
  final Color faint;

  /// Keys, links and focus.
  final Color accent;

  /// Text on [accent].
  final Color onAccent;

  /// Success.
  final Color green;

  /// Errors and exit.
  final Color red;

  /// Running and prompt.
  final Color amber;

  /// Sub menus.
  final Color purple;

  /// The colors of the current theme, dark if not set.
  static TestMenuColors of(BuildContext context) =>
      Theme.of(context).extension<TestMenuColors>() ?? dark;

  @override
  TestMenuColors copyWith({
    Color? background,
    Color? dot,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? border,
    Color? text,
    Color? muted,
    Color? faint,
    Color? accent,
    Color? onAccent,
    Color? green,
    Color? red,
    Color? amber,
    Color? purple,
  }) {
    return TestMenuColors(
      background: background ?? this.background,
      dot: dot ?? this.dot,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      green: green ?? this.green,
      red: red ?? this.red,
      amber: amber ?? this.amber,
      purple: purple ?? this.purple,
    );
  }

  @override
  TestMenuColors lerp(TestMenuColors? other, double t) {
    if (other == null) {
      return this;
    }
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TestMenuColors(
      background: l(background, other.background),
      dot: l(dot, other.dot),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      surface3: l(surface3, other.surface3),
      border: l(border, other.border),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      green: l(green, other.green),
      red: l(red, other.red),
      amber: l(amber, other.amber),
      purple: l(purple, other.purple),
    );
  }
}

/// Console theme (monospace), only used for the menu page so that the pages
/// pushed by the items keep the regular material look.
ThemeData testMenuConsoleThemeData(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? TestMenuColors.dark
      : TestMenuColors.light;
  final base = ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      surface: colors.surface,
      onSurface: colors.text,
      error: colors.red,
    ),
    scaffoldBackgroundColor: colors.background,
    fontFamily: 'monospace',
    fontFamilyFallback: _monospaceFallback,
    visualDensity: VisualDensity.compact,
    extensions: [colors],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
      fontFamily: 'monospace',
      fontFamilyFallback: _monospaceFallback,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      textStyle: TextStyle(
        color: colors.surface,
        fontSize: 12,
        fontFamily: 'monospace',
        fontFamilyFallback: _monospaceFallback,
      ),
      decoration: BoxDecoration(
        color: colors.text,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.accent,
      selectionColor: colors.accent.withValues(alpha: 0.3),
    ),
    checkboxTheme: CheckboxThemeData(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: colors.muted, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(colors.onAccent),
    ),
  );
}

/// Regular material theme of the app, for the pages pushed by the items.
ThemeData testMenuAppThemeData(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark
          ? TestMenuColors.dark.accent
          : TestMenuColors.light.accent,
      brightness: brightness,
    ),
  );
}
