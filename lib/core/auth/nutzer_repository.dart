import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock/mock_store.dart';
import 'nutzer_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `nutzer`.
///
/// Die Tabelle existiert bereits inkl. RLS – hier wird ausschließlich
/// gelesen/geschrieben, niemals das Schema verändert.
abstract class NutzerRepository {
  /// Lädt die eigene `nutzer`-Zeile. Liefert `null`, wenn noch keine Zeile
  /// existiert (Onboarding-Fall) oder RLS den Zugriff verweigert.
  Future<Nutzer?> getNutzer(String id);

  /// Legt direkt nach erfolgreichem Signup die `nutzer`-Zeile an
  /// (id = auth.uid()).
  Future<Nutzer> nutzerAnlegen({
    required String id,
    required String name,
    required String email,
    required NutzerRolle rolle,
  });

  /// Suche für Trainer, um Schüler per E-Mail oder Name zu finden.
  Future<List<Nutzer>> sucheNutzer({required String suchbegriff, NutzerRolle? rolle});
}

class SupabaseNutzerRepository implements NutzerRepository {
  SupabaseNutzerRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Nutzer?> getNutzer(String id) async {
    final data = await _client
        .from('nutzer')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Nutzer.fromMap(data);
  }

  @override
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

  @override
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

/// Demo-/Vorschau-Modus: liefert/verändert die geteilten [MockStore]-Daten.
class MockNutzerRepository implements NutzerRepository {
  final _store = MockStore.instance;

  @override
  Future<Nutzer?> getNutzer(String id) async {
    for (final n in _store.nutzer) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  Future<Nutzer> nutzerAnlegen({
    required String id,
    required String name,
    required String email,
    required NutzerRolle rolle,
  }) async {
    final nutzer = Nutzer(id: id, name: name, email: email, rolle: rolle);
    _store.nutzer.add(nutzer);
    return nutzer;
  }

  @override
  Future<List<Nutzer>> sucheNutzer({
    required String suchbegriff,
    NutzerRolle? rolle,
  }) async {
    final begriff = suchbegriff.trim().toLowerCase();
    if (begriff.isEmpty) return [];
    return _store.nutzer.where((n) {
      final passtRolle = rolle == null || n.rolle == rolle;
      final passtSuche =
          n.name.toLowerCase().contains(begriff) || n.email.toLowerCase().contains(begriff);
      return passtRolle && passtSuche;
    }).toList();
  }
}
