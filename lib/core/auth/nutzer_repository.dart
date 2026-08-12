import 'package:supabase_flutter/supabase_flutter.dart';

import 'nutzer_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `nutzer`.
///
/// Die Tabelle existiert bereits inkl. RLS – hier wird ausschließlich
/// gelesen/geschrieben, niemals das Schema verändert.
class NutzerRepository {
  NutzerRepository(this._client);

  final SupabaseClient _client;

  /// Lädt die eigene `nutzer`-Zeile. Liefert `null`, wenn noch keine Zeile
  /// existiert (Onboarding-Fall) oder RLS den Zugriff verweigert.
  Future<Nutzer?> getNutzer(String id) async {
    final data = await _client
        .from('nutzer')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Nutzer.fromMap(data);
  }

  /// Legt direkt nach erfolgreichem Signup die `nutzer`-Zeile an
  /// (id = auth.uid()).
  Future<Nutzer> nutzerAnlegen({
    required String id,
    required String name,
    required String email,
    required NutzerRolle rolle,
  }) async {
    final data = await _client
        .from('nutzer')
        .insert({
          'id': id,
          'name': name,
          'email': email,
          'rolle': rolle.wert,
        })
        .select()
        .single();
    return Nutzer.fromMap(data);
  }

  /// Suche für Trainer, um Schüler per E-Mail oder Name zu finden.
  Future<List<Nutzer>> sucheNutzer({
    required String suchbegriff,
    NutzerRolle? rolle,
  }) async {
    final begriff = suchbegriff.trim();
    if (begriff.isEmpty) return [];

    var query = _client
        .from('nutzer')
        .select()
        .or('name.ilike.%$begriff%,email.ilike.%$begriff%');
    if (rolle != null) {
      query = query.eq('rolle', rolle.wert);
    }

    final data = await query.limit(20);
    return (data as List)
        .map((row) => Nutzer.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
