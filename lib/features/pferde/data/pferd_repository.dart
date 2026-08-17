import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_store.dart';
import '../domain/pferd_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `pferd`.
abstract class PferdRepository {
  /// Alle Pferde eines Reiters (Schüler), z. B. für Auswahl in Termin,
  /// Trainingsstunde oder Trainingsplan.
  Future<List<Pferd>> getPferdeFuerReiter(String reiterId);
}

class SupabasePferdRepository implements PferdRepository {
  SupabasePferdRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Pferd>> getPferdeFuerReiter(String reiterId) async {
    final data = await _client.from('pferd').select().eq('reiter_id', reiterId);
    return (data as List)
        .map((row) => Pferd.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}

/// Demo-/Vorschau-Modus: liest aus dem geteilten [MockStore].
class MockPferdRepository implements PferdRepository {
  final _store = MockStore.instance;

  @override
  Future<List<Pferd>> getPferdeFuerReiter(String reiterId) async {
    return _store.pferde.where((p) => p.reiterId == reiterId).toList();
  }
}
