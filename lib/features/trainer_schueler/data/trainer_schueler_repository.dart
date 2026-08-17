import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trainer_schueler_model.dart';

/// Kapselt sämtliche Zugriffe auf `trainer_schueler`.
class TrainerSchuelerRepository {
  TrainerSchuelerRepository(this._client);

  final SupabaseClient _client;

  /// Trainer legt eine Anfrage an einen Schüler an (status='angefragt').
  Future<void> anfrageErstellen({
    required String trainerId,
    required String schuelerId,
  }) async {
    await _client.from('trainer_schueler').insert({
      'trainer_id': trainerId,
      'schueler_id': schuelerId,
      'status': TrainerSchuelerStatus.angefragt.wert,
    });
  }

  /// Alle Verknüpfungen eines Trainers, inkl. Schüler-Stammdaten.
  Future<List<TrainerSchuelerEintrag>> getSchuelerFuerTrainer(String trainerId) async {
    final data = await _client
        .from('trainer_schueler')
        .select('trainer_id, schueler_id, status, schueler:schueler_id(*)')
        .eq('trainer_id', trainerId);
    return (data as List)
        .map((row) => TrainerSchuelerEintrag.fromMap(
              row as Map<String, dynamic>,
              gegenueberSchluessel: 'schueler',
            ))
        .toList();
  }

  /// Nur die aktiven Schüler eines Trainers (für Termin-/Planauswahl).
  Future<List<TrainerSchuelerEintrag>> getAktiveSchuelerFuerTrainer(String trainerId) async {
    final alle = await getSchuelerFuerTrainer(trainerId);
    return alle.where((e) => e.status == TrainerSchuelerStatus.aktiv).toList();
  }

  /// Alle Verknüpfungen eines Schülers, inkl. Trainer-Stammdaten.
  Future<List<TrainerSchuelerEintrag>> getTrainerFuerSchueler(String schuelerId) async {
    final data = await _client
        .from('trainer_schueler')
        .select('trainer_id, schueler_id, status, trainer:trainer_id(*)')
        .eq('schueler_id', schuelerId);
    return (data as List)
        .map((row) => TrainerSchuelerEintrag.fromMap(
              row as Map<String, dynamic>,
              gegenueberSchluessel: 'trainer',
            ))
        .toList();
  }

  /// Schüler bestätigt oder beendet eine Verknüpfung.
  Future<void> statusAktualisieren({
    required String trainerId,
    required String schuelerId,
    required TrainerSchuelerStatus status,
  }) async {
    await _client
        .from('trainer_schueler')
        .update({'status': status.wert})
        .eq('trainer_id', trainerId)
        .eq('schueler_id', schuelerId);
  }
}
