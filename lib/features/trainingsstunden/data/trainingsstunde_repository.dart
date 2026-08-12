import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trainingsstunde_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `trainingsstunde`.
class TrainingsstundeRepository {
  TrainingsstundeRepository(this._client);

  final SupabaseClient _client;

  Future<List<Trainingsstunde>> getFuerSchueler(String schuelerId) async {
    final data = await _client
        .from('trainingsstunde')
        .select()
        .eq('schueler_id', schuelerId)
        .order('datum', ascending: false);
    return (data as List)
        .map((row) => Trainingsstunde.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> anlegen(Trainingsstunde stunde) async {
    await _client.from('trainingsstunde').insert(stunde.toInsertMap());
  }

  /// Eigene Trainingspläne (schlanke Projektion) zur Auswahl beim Erfassen
  /// einer Stunde.
  Future<List<TrainingsplanKurz>> getEigenePlaeneKurz(String schuelerId) async {
    final data = await _client
        .from('trainingsplan')
        .select('id, anfang, ende')
        .eq('nutzer_id', schuelerId)
        .order('anfang', ascending: false);
    return (data as List)
        .map((row) => TrainingsplanKurz.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
