import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/pferd_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `pferd`.
class PferdRepository {
  PferdRepository(this._client);

  final SupabaseClient _client;

  /// Alle Pferde eines Reiters (Schüler), z. B. für Auswahl in Termin,
  /// Trainingsstunde oder Trainingsplan.
  Future<List<Pferd>> getPferdeFuerReiter(String reiterId) async {
    final data = await _client.from('pferd').select().eq('reiter_id', reiterId);
    return (data as List)
        .map((row) => Pferd.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
