import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task.dart';

/// Cores do Rumo que não cabem no ColorScheme do Material.
@immutable
class RumoColors extends ThemeExtension<RumoColors> {
  const RumoColors({
    required this.surface2,
    required this.line,
    required this.muted,
    required this.high,
    required this.medium,
    required this.low,
    required this.none,
    required this.ringTrack,
    required this.projects,
  });

  final Color surface2;
  final Color line;
  final Color muted;
  final Color high;
  final Color medium;
  final Color low;
  final Color none;
  final Color ringTrack;
  final Map<String, Color> projects;

  static const light = RumoColors(
    surface2: Color(0xFFF2F4F8),
    line: Color(0xFFE1E5ED),
    muted: Color(0xFF677085),
    high: Color(0xFFE2484D),
    medium: Color(0xFFE08A0B),
    low: Color(0xFF2F9467),
    none: Color(0xFFAEB5C4),
    ringTrack: Color(0xFFE3E7EF),
    projects: {
      'blue': Color(0xFF2D5BE3),
      'orange': Color(0xFFD97A2B),
      'green': Color(0xFF2F9467),
      'violet': Color(0xFF8A57E8),
    },
  );

  static const dark = RumoColors(
    surface2: Color(0xFF1C2230),
    line: Color(0xFF252C3A),
    muted: Color(0xFF8D96AA),
    high: Color(0xFFFF6B6E),
    medium: Color(0xFFF5A524),
    low: Color(0xFF3DBE86),
    none: Color(0xFF4C5568),
    ringTrack: Color(0xFF273042),
    projects: {
      'blue': Color(0xFF7090FF),
      'orange': Color(0xFFF09A50),
      'green': Color(0xFF3DBE86),
      'violet': Color(0xFFA983FF),
    },
  );

  Color priority(Priority p) => switch (p) {
        Priority.high => high,
        Priority.medium => medium,
        Priority.low => low,
        Priority.none => none,
      };

  Color project(Project p) => projects[p.color] ?? projects['blue']!;

  @override
  RumoColors copyWith() => this;

  @override
  RumoColors lerp(RumoColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RumoColors(
      surface2: l(surface2, other.surface2),
      line: l(line, other.line),
      muted: l(muted, other.muted),
      high: l(high, other.high),
      medium: l(medium, other.medium),
      low: l(low, other.low),
      none: l(none, other.none),
      ringTrack: l(ringTrack, other.ringTrack),
      projects: {for (final k in projects.keys) k: l(projects[k]!, other.projects[k] ?? projects[k]!)},
    );
  }
}

extension RumoThemeContext on BuildContext {
  RumoColors get rc => Theme.of(this).extension<RumoColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
}

/// Nos testes as fontes do Google não são baixadas; passe `fontFamily`.
ThemeData buildTheme(Brightness brightness, {String? fontFamily}) {
  final dark = brightness == Brightness.dark;
  final rc = dark ? RumoColors.dark : RumoColors.light;
  final accent = dark ? const Color(0xFF7090FF) : const Color(0xFF2D5BE3);
  final ink = dark ? const Color(0xFFE9EDF5) : const Color(0xFF141925);
  final surface = dark ? const Color(0xFF151A24) : Colors.white;

  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2D5BE3), brightness: brightness).copyWith(
    primary: accent,
    onPrimary: dark ? const Color(0xFF0B0E14) : Colors.white,
    primaryContainer: dark ? const Color(0xFF1D2747) : const Color(0xFFE4EBFC),
    onPrimaryContainer: accent,
    secondaryContainer: dark ? const Color(0xFF1D2747) : const Color(0xFFE4EBFC),
    onSecondaryContainer: accent,
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: rc.muted,
    surfaceContainerLowest: surface,
    surfaceContainerLow: rc.surface2,
    surfaceContainer: rc.surface2,
    surfaceContainerHigh: rc.surface2,
    outline: rc.line,
    outlineVariant: rc.line,
    error: rc.high,
    inverseSurface: ink,
    onInverseSurface: surface,
    inversePrimary: dark ? const Color(0xFF2D5BE3) : const Color(0xFFA9BEFF),
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: fontFamily);
  final bodyFamily = fontFamily ?? GoogleFonts.figtree().fontFamily;
  var text = base.textTheme.apply(fontFamily: bodyFamily, bodyColor: ink, displayColor: ink);

  TextStyle display(TextStyle? s, double size, FontWeight w, double spacing) {
    final style = (s ?? const TextStyle()).copyWith(fontSize: size, fontWeight: w, letterSpacing: spacing, height: 1.1);
    return fontFamily == null ? GoogleFonts.bricolageGrotesque(textStyle: style) : style;
  }

  text = text.copyWith(
    displaySmall: display(text.displaySmall, 36, FontWeight.w700, -1.2),
    headlineSmall: display(text.headlineSmall, 22, FontWeight.w600, -0.4),
    titleLarge: display(text.titleLarge, 20, FontWeight.w600, -0.3),
    titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
    bodyLarge: text.bodyLarge?.copyWith(fontSize: 15, height: 1.35),
    labelSmall: text.labelSmall?.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.0),
  );

  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return base.copyWith(
    scaffoldBackgroundColor: surface,
    textTheme: text,
    extensions: [rc],
    dividerTheme: DividerThemeData(color: rc.line, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? accent : rc.muted,
          fontFamily: text.bodyMedium?.fontFamily,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? accent : rc.muted),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        minimumSize: const Size(0, 46),
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, fontFamily: bodyFamily),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, fontFamily: bodyFamily)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: bodyFamily)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: rc.line),
      backgroundColor: surface,
      selectedColor: ink,
      secondarySelectedColor: ink,
      checkmarkColor: surface,
      labelStyle: TextStyle(color: ink, fontSize: 13, fontFamily: text.bodyMedium?.fontFamily),
      secondaryLabelStyle: TextStyle(color: surface, fontSize: 13, fontFamily: text.bodyMedium?.fontFamily),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: rc.line,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: TextStyle(color: surface, fontWeight: FontWeight.w500, fontFamily: text.bodyMedium?.fontFamily),
      actionTextColor: dark ? const Color(0xFF2D5BE3) : const Color(0xFFA9BEFF),
      shape: rounded,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: rc.none),
    ),
  );
}

/// Números alinhados (horários, contadores, timer).
TextStyle monoStyle(BuildContext context, {double size = 12, FontWeight weight = FontWeight.w500, Color? color}) {
  final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
  final style = TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  final usingGoogleFonts = family != null && family.startsWith('Figtree');
  return usingGoogleFonts ? GoogleFonts.jetBrainsMono(textStyle: style) : style.copyWith(fontFamily: family);
}
