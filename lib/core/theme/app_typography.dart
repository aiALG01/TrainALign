import 'package:flutter/material.dart';

/// Einzige Stelle für die Schriftwahl der App.
///
/// Aktuell `null` (Flutter/Material-3-Systemschrift). Später:
///   [headlineFontFamily] -> "Boska" (Serif, Headlines)
///   [bodyFontFamily]     -> "Ranade" (Sans, Body)
/// Sobald die Fonts als Assets/Pakete eingebunden sind, reicht es, die
/// beiden Konstanten unten zu setzen – [AppTheme] baut die `TextTheme`
/// darauf auf.
class AppTypography {
  const AppTypography._();

  static const String? headlineFontFamily = null;
  static const String? bodyFontFamily = null;

  static TextTheme textTheme(TextTheme base) {
    final withBody = bodyFontFamily == null
        ? base
        : base.apply(fontFamily: bodyFontFamily);

    if (headlineFontFamily == null) {
      return withBody;
    }

    return withBody.copyWith(
      displayLarge: withBody.displayLarge?.copyWith(fontFamily: headlineFontFamily),
      displayMedium: withBody.displayMedium?.copyWith(fontFamily: headlineFontFamily),
      displaySmall: withBody.displaySmall?.copyWith(fontFamily: headlineFontFamily),
      headlineLarge: withBody.headlineLarge?.copyWith(fontFamily: headlineFontFamily),
      headlineMedium: withBody.headlineMedium?.copyWith(fontFamily: headlineFontFamily),
      headlineSmall: withBody.headlineSmall?.copyWith(fontFamily: headlineFontFamily),
      titleLarge: withBody.titleLarge?.copyWith(fontFamily: headlineFontFamily),
    );
  }
}
