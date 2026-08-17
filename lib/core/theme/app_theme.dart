import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';

/// Zentrales, einziges `ThemeData` der App (Material 3, neutral).
///
/// Farben und Schriften werden ausschließlich aus [AppPalette] bzw.
/// [AppTypography] bezogen, damit das spätere Branding an genau einer
/// Stelle eingehängt werden kann.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seed,
      error: AppPalette.error,
      brightness: Brightness.light,
    );
    return _build(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seed,
      error: AppPalette.error,
      brightness: Brightness.dark,
    );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      // copyWith statt eines konkreten Klassennamens (CardTheme/CardThemeData
      // wurde je nach Flutter-Version umbenannt) – so bleibt das über einen
      // größeren Versionsbereich hinweg kompatibel.
      cardTheme: base.cardTheme.copyWith(clipBehavior: Clip.antiAlias),
    );
  }
}
