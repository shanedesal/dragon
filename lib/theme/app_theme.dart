import 'package:flutter/material.dart';

/// Catppuccin Mocha color palette
class CatppuccinMocha {
  CatppuccinMocha._();

  // Accents
  static const Color rosewater = Color(0xFFf5e0dc);
  static const Color flamingo  = Color(0xFFf2cdcd);
  static const Color pink      = Color(0xFFf5c2e7);
  static const Color mauve     = Color(0xFFcba6f7);
  static const Color red       = Color(0xFFf38ba8);
  static const Color maroon    = Color(0xFFeba0ac);
  static const Color peach     = Color(0xFFfab387);
  static const Color yellow    = Color(0xFFf9e2af);
  static const Color green     = Color(0xFFa6e3a1);
  static const Color teal      = Color(0xFF94e2d5);
  static const Color sky       = Color(0xFF89dceb);
  static const Color sapphire  = Color(0xFF74c7ec);
  static const Color blue      = Color(0xFF89b4fa);
  static const Color lavender  = Color(0xFFb4befe);

  // Text
  static const Color text     = Color(0xFFcdd6f4);
  static const Color subtext1 = Color(0xFFbac2de);
  static const Color subtext0 = Color(0xFFa6adc8);

  // Overlays
  static const Color overlay2 = Color(0xFF9399b2);
  static const Color overlay1 = Color(0xFF7f849c);
  static const Color overlay0 = Color(0xFF6c7086);

  // Surfaces
  static const Color surface2 = Color(0xFF585b70);
  static const Color surface1 = Color(0xFF45475a);
  static const Color surface0 = Color(0xFF313244);

  // Backgrounds
  static const Color base    = Color(0xFF1e1e2e);
  static const Color mantle  = Color(0xFF181825);
  static const Color crust   = Color(0xFF11111b);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CatppuccinMocha.base,
      colorScheme: const ColorScheme.dark(
        primary: CatppuccinMocha.mauve,
        onPrimary: CatppuccinMocha.crust,
        secondary: CatppuccinMocha.blue,
        onSecondary: CatppuccinMocha.crust,
        tertiary: CatppuccinMocha.teal,
        onTertiary: CatppuccinMocha.crust,
        surface: CatppuccinMocha.base,
        onSurface: CatppuccinMocha.text,
        error: CatppuccinMocha.red,
        onError: CatppuccinMocha.crust,
        outline: CatppuccinMocha.overlay0,
        surfaceContainerHighest: CatppuccinMocha.surface0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: CatppuccinMocha.text,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: CatppuccinMocha.text,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: CatppuccinMocha.text,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: CatppuccinMocha.text,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: CatppuccinMocha.text),
        bodyMedium: TextStyle(color: CatppuccinMocha.subtext1),
        bodySmall: TextStyle(color: CatppuccinMocha.subtext0),
        labelLarge: TextStyle(
          color: CatppuccinMocha.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CatppuccinMocha.surface0,
        hintStyle: const TextStyle(color: CatppuccinMocha.overlay0),
        labelStyle: const TextStyle(color: CatppuccinMocha.overlay2),
        floatingLabelStyle: const TextStyle(color: CatppuccinMocha.mauve),
        prefixIconColor: CatppuccinMocha.overlay2,
        suffixIconColor: CatppuccinMocha.overlay2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.surface1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.surface1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.mauve, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.red, width: 2),
        ),
        errorStyle: const TextStyle(color: CatppuccinMocha.red),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CatppuccinMocha.mauve,
          foregroundColor: CatppuccinMocha.crust,
          disabledBackgroundColor: CatppuccinMocha.surface1,
          disabledForegroundColor: CatppuccinMocha.overlay0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CatppuccinMocha.mauve,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CatppuccinMocha.mantle,
        foregroundColor: CatppuccinMocha.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: CatppuccinMocha.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: CatppuccinMocha.subtext1),
      ),
      cardTheme: CardThemeData(
        color: CatppuccinMocha.surface0,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CatppuccinMocha.surface1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: CatppuccinMocha.surface1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: CatppuccinMocha.subtext1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CatppuccinMocha.mantle,
        indicatorColor: Color.fromRGBO(203, 166, 247, 0.2),
      ),
    );
  }
}
