import 'package:flutter/material.dart';
import 'package:zapateria_flutter/components/neo_style.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  ThemeData get theme => _isDark ? _darkTheme : _lightTheme;

  // Neobrutalist / playful direction — see DESIGN.md. Bold black outlines,
  // flat cards (no soft shadow; NeoCard adds the hard offset shadow where
  // used directly), one accent color (NeoColors.accent) across both themes.

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: NeoColors.inkLight,
      onPrimary: NeoColors.paperLight,
      secondary: NeoColors.accent,
      onSecondary: NeoColors.inkLight,
      surface: NeoColors.paperLight,
      primaryContainer: NeoColors.accent.withOpacity(0.35),
      onPrimaryContainer: NeoColors.inkLight,
      secondaryContainer: NeoColors.accent.withOpacity(0.35),
      onSecondaryContainer: NeoColors.inkLight,
      outline: NeoColors.inkLight,
    ),
    dividerColor: NeoColors.inkLight.withOpacity(0.12),
    hoverColor: NeoColors.inkLight.withOpacity(0.07),
    scaffoldBackgroundColor: NeoColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: NeoColors.bgLight,
      foregroundColor: NeoColors.inkLight,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: NeoColors.inkLight),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: NeoColors.bgLight,
      indicatorColor: NeoColors.accent,
      selectedIconTheme: const IconThemeData(color: NeoColors.inkLight),
      selectedLabelTextStyle: const TextStyle(color: NeoColors.inkLight, fontWeight: FontWeight.w800),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: NeoColors.paperLight,
      selectedItemColor: NeoColors.inkLight,
      unselectedItemColor: NeoColors.inkLight.withOpacity(0.4),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: NeoColors.paperLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeoColors.inkLight, width: 2),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeoColors.paperLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NeoColors.inkLight, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NeoColors.inkLight, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NeoColors.accent, width: 3)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NeoColors.accent,
        foregroundColor: NeoColors.inkLight,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.inkLight, width: 2),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NeoColors.accent,
        foregroundColor: NeoColors.inkLight,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.inkLight, width: 2),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NeoColors.inkLight,
        side: const BorderSide(color: NeoColors.inkLight, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: NeoColors.accent,
      foregroundColor: NeoColors.inkLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeoColors.inkLight, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: NeoColors.paperLight,
      selectedColor: NeoColors.accent,
      side: const BorderSide(color: NeoColors.inkLight, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: NeoColors.inkLight),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: NeoColors.inkLight),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NeoColors.inkLight),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: NeoColors.inkLight),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NeoColors.inkLight),
      bodyLarge: TextStyle(fontSize: 16, color: NeoColors.inkLight),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF767676)),
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: NeoColors.inkDark,
      onPrimary: NeoColors.inkLight,
      secondary: NeoColors.accent,
      onSecondary: NeoColors.inkLight,
      surface: NeoColors.paperDark,
      primaryContainer: NeoColors.accent.withOpacity(0.25),
      onPrimaryContainer: NeoColors.inkDark,
      secondaryContainer: NeoColors.accent.withOpacity(0.25),
      onSecondaryContainer: NeoColors.inkDark,
      outline: NeoColors.inkDark,
    ),
    dividerColor: NeoColors.inkDark.withOpacity(0.15),
    hoverColor: NeoColors.inkDark.withOpacity(0.08),
    scaffoldBackgroundColor: NeoColors.bgDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: NeoColors.bgDark,
      foregroundColor: NeoColors.inkDark,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: NeoColors.inkDark),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: NeoColors.bgDark,
      indicatorColor: NeoColors.accent,
      selectedIconTheme: const IconThemeData(color: NeoColors.inkLight),
      selectedLabelTextStyle: const TextStyle(color: NeoColors.inkDark, fontWeight: FontWeight.w800),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: NeoColors.paperDark,
      selectedItemColor: NeoColors.inkDark,
      unselectedItemColor: NeoColors.inkDark.withOpacity(0.4),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: NeoColors.paperDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeoColors.inkDark, width: 2),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeoColors.paperDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NeoColors.inkDark, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NeoColors.inkDark, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NeoColors.accent, width: 3)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NeoColors.accent,
        foregroundColor: NeoColors.inkLight,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.inkDark, width: 2),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NeoColors.accent,
        foregroundColor: NeoColors.inkLight,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.inkDark, width: 2),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NeoColors.inkDark,
        side: const BorderSide(color: NeoColors.inkDark, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: NeoColors.accent,
      foregroundColor: NeoColors.inkLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeoColors.inkDark, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: NeoColors.paperDark,
      selectedColor: NeoColors.accent,
      side: const BorderSide(color: NeoColors.inkDark, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: NeoColors.inkDark),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: NeoColors.inkDark),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NeoColors.inkDark),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: NeoColors.inkDark),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NeoColors.inkDark),
      bodyLarge: TextStyle(fontSize: 16, color: NeoColors.inkDark),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFBFBFBF)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF8C8C8C)),
    ),
  );
}
