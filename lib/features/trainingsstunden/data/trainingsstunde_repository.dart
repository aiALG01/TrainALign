import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_store.dart';
import '../domain/trainingsstunde_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `trainingsstunde`.
abstract class TrainingsstundeRepository {
  Future<List<Trainingsstunde>> getFuerSchueler(String schuelerId);

  Future<void> anlegen(Trainingsstunde stunde);

  /// Eigene Trainingspläne (schlanke Projektion) zur Auswahl beim Erfassen
  /// einer Stunde.
  Future<List<TrainingsplanKurz>> getEigenePlaeneKurz(String schuelerId);
}

class SupabaseTrainingsstundeRepository implements TrainingsstundeRepository {
  SupabaseTrainingsstundeRepository(this._client);

  final SupabaseClient _client;

  @override
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

  @override
  Future<void> anlegen(Trainingsstunde stunde) async {
    await _client.from('trainingsstunde').insert(stunde.toInsertMap());
  }

  @override
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

/// Demo-/Vorschau-Modus: liest/verändert die geteilten [MockStore]-Daten.
class MockTrainingsstundeRepository implements TrainingsstundeRepository {
  final _store = MockStore.instance;

  @override
  Future<List<Trainingsstunde>> getFuerSchueler(String schuelerId) async {
    return _store.trainingsstunden.where((s) => s.schuelerId == schuelerId).toList()
      ..sort((a, b) => b.datum.compareTo(a.datum));
  }

  @override
  Future<void> anlegen(Trainingsstunde stunde) async {
    _store.trainingsstunden.add(
      Trainingsstunde(
        id: _store.neueId('mock-stunde'),
        schuelerId: stunde.schuelerId,
        trainerId: stunde.trainerId,
        pferdId: stunde.pferdId,
        trainingsplanId: stunde.trainingsplanId,
        mitTrainer: stunde.mitTrainer,
        datum: stunde.datum,
        dauerMinuten: stunde.dauerMinuten,
        bewertung: stunde.bewertung,
        kommentar: stunde.kommentar,
      ),
    );
  }

  @override
  Future<List<TrainingsplanKurz>> getEigenePlaeneKurz(String schuelerId) async {
    return _store.trainingsplaene
        .where((p) => p.nutzerId == schuelerId)
        .map((p) => TrainingsplanKurz(id: p.id!, anfang: p.anfang, ende: p.ende))
        .toList();
  }
}
