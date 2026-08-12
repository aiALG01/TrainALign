import 'package:flutter/material.dart';

/// Einzige Stelle für Marken-/Akzentfarben der App.
///
/// Aktuell neutrales Material-3-Blau als Platzhalter. Das spätere Branding
/// ersetzt ausschließlich die Werte unten (keine anderen Stellen im Code
/// müssen angepasst werden):
///   Dunkelgrün #005246, Mint #77CB89, Lavendel #817E9F,
///   Beige #CEBCA1, Bordeaux #220C10
class AppPalette {
  const AppPalette._();

  /// Seed-Farbe für die dynamisch generierte Material-3-`ColorScheme`.
  /// Später: Color(0xFF005246) (Dunkelgrün).
  static const Color seed = Color(0xFF3E6FE0);

  /// Optionaler Fehlerfarb-Seed. Später ggf. Color(0xFF220C10) (Bordeaux).
  static const Color error = Color(0xFFBA1A1A);
}
