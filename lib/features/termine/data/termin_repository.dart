import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/termin_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `termin`.
class TerminRepository {
  TerminRepository(this._client);

  final SupabaseClient _client;

  Future<List<Termin>> getTermineFuerTrainer(String trainerId) async {
    final data = await _client
        .from('termin')
        .select()
        .eq('trainer_id', trainerId)
        .order('beginn');
    return (data as List).map((row) => Termin.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<List<Termin>> getTermineFuerSchueler(String schuelerId) async {
    final data = await _client
        .from('termin')
        .select()
        .eq('schueler_id', schuelerId)
        .order('beginn');
    return (data as List).map((row) => Termin.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<void> anlegen(Termin termin) async {
    await _client.from('termin').insert(termin.toInsertMap());
  }

  Future<void> aktualisieren(String id, Termin termin) async {
    await _client.from('termin').update(termin.toInsertMap()).eq('id', id);
  }

  Future<void> statusAktualisieren(String id, TerminStatus status) async {
    await _client.from('termin').update({'status': status.wert}).eq('id', id);
  }
}
