import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_store.dart';
import '../domain/trainer_schueler_model.dart';

/// Kapselt sämtliche Zugriffe auf `trainer_schueler`.
abstract class TrainerSchuelerRepository {
  /// Trainer legt eine Anfrage an einen Schüler an (status='angefragt').
  Future<void> anfrageErstellen({required String trainerId, required String schuelerId});

  /// Alle Verknüpfungen eines Trainers, inkl. Schüler-Stammdaten.
  Future<List<TrainerSchuelerEintrag>> getSchuelerFuerTrainer(String trainerId);

  /// Nur die aktiven Schüler eines Trainers (für Termin-/Planauswahl).
  Future<List<TrainerSchuelerEintrag>> getAktiveSchuelerFuerTrainer(String trainerId);

  /// Alle Verknüpfungen eines Schülers, inkl. Trainer-Stammdaten.
  Future<List<TrainerSchuelerEintrag>> getTrainerFuerSchueler(String schuelerId);

  /// Schüler bestätigt oder beendet eine Verknüpfung.
  Future<void> statusAktualisieren({
    required String trainerId,
    required String schuelerId,
    required TrainerSchuelerStatus status,
  });
}

class SupabaseTrainerSchuelerRepository implements TrainerSchuelerRepository {
  SupabaseTrainerSchuelerRepository(this._client);

  final SupabaseClient _client;

  @override
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

  @override
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

  @override
  Future<List<TrainerSchuelerEintrag>> getAktiveSchuelerFuerTrainer(String trainerId) async {
    final alle = await getSchuelerFuerTrainer(trainerId);
    return alle.where((e) => e.status == TrainerSchuelerStatus.aktiv).toList();
  }

  @override
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

  @override
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

/// Demo-/Vorschau-Modus: liest/verändert die geteilten [MockStore]-Daten.
class MockTrainerSchuelerRepository implements TrainerSchuelerRepository {
  final _store = MockStore.instance;

  @override
  Future<void> anfrageErstellen({
    required String trainerId,
    required String schuelerId,
  }) async {
    _store.trainerSchueler.add(
      TrainerSchuelerEintrag(
        trainerId: trainerId,
        schuelerId: schuelerId,
        status: TrainerSchuelerStatus.angefragt,
        gegenueber: _store.nutzerMitId(schuelerId),
      ),
    );
  }

  @override
  Future<List<TrainerSchuelerEintrag>> getSchuelerFuerTrainer(String trainerId) async {
    return _store.trainerSchueler.where((e) => e.trainerId == trainerId).toList();
  }

  @override
  Future<List<TrainerSchuelerEintrag>> getAktiveSchuelerFuerTrainer(String trainerId) async {
    final alle = await getSchuelerFuerTrainer(trainerId);
    return alle.where((e) => e.status == TrainerSchuelerStatus.aktiv).toList();
  }

  @override
  Future<List<TrainerSchuelerEintrag>> getTrainerFuerSchueler(String schuelerId) async {
    return _store.trainerSchueler.where((e) => e.schuelerId == schuelerId).toList();
  }

  @override
  Future<void> statusAktualisieren({
    required String trainerId,
    required String schuelerId,
    required TrainerSchuelerStatus status,
  }) async {
    final index = _store.trainerSchueler.indexWhere(
      (e) => e.trainerId == trainerId && e.schuelerId == schuelerId,
    );
    if (index == -1) return;
    final alt = _store.trainerSchueler[index];
    _store.trainerSchueler[index] = TrainerSchuelerEintrag(
      trainerId: alt.trainerId,
      schuelerId: alt.schuelerId,
      status: status,
      gegenueber: alt.gegenueber,
    );
  }
}
