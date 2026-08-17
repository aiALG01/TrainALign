import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_store.dart';
import '../domain/termin_model.dart';

/// Kapselt sämtliche Zugriffe auf die Tabelle `termin`.
abstract class TerminRepository {
  Future<List<Termin>> getTermineFuerTrainer(String trainerId);

  Future<List<Termin>> getTermineFuerSchueler(String schuelerId);

  Future<void> anlegen(Termin termin);

  Future<void> aktualisieren(String id, Termin termin);

  Future<void> statusAktualisieren(String id, TerminStatus status);
}

class SupabaseTerminRepository implements TerminRepository {
  SupabaseTerminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Termin>> getTermineFuerTrainer(String trainerId) async {
    final data = await _client
        .from('termin')
        .select()
        .eq('trainer_id', trainerId)
        .order('beginn');
    return (data as List).map((row) => Termin.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Termin>> getTermineFuerSchueler(String schuelerId) async {
    final data = await _client
        .from('termin')
        .select()
        .eq('schueler_id', schuelerId)
        .order('beginn');
    return (data as List).map((row) => Termin.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> anlegen(Termin termin) async {
    await _client.from('termin').insert(termin.toInsertMap());
  }

  @override
  Future<void> aktualisieren(String id, Termin termin) async {
    await _client.from('termin').update(termin.toInsertMap()).eq('id', id);
  }

  @override
  Future<void> statusAktualisieren(String id, TerminStatus status) async {
    await _client.from('termin').update({'status': status.wert}).eq('id', id);
  }
}

/// Demo-/Vorschau-Modus: liest/verändert die geteilten [MockStore]-Daten.
class MockTerminRepository implements TerminRepository {
  final _store = MockStore.instance;

  @override
  Future<List<Termin>> getTermineFuerTrainer(String trainerId) async {
    return _store.termine.where((t) => t.trainerId == trainerId).toList()
      ..sort((a, b) => a.beginn.compareTo(b.beginn));
  }

  @override
  Future<List<Termin>> getTermineFuerSchueler(String schuelerId) async {
    return _store.termine.where((t) => t.schuelerId == schuelerId).toList()
      ..sort((a, b) => a.beginn.compareTo(b.beginn));
  }

  @override
  Future<void> anlegen(Termin termin) async {
    _store.termine.add(
      Termin(
        id: _store.neueId('mock-termin'),
        trainerId: termin.trainerId,
        schuelerId: termin.schuelerId,
        pferdId: termin.pferdId,
        beginn: termin.beginn,
        ende: termin.ende,
        ort: termin.ort,
        typ: termin.typ,
        status: termin.status,
        notiz: termin.notiz,
      ),
    );
  }

  @override
  Future<void> aktualisieren(String id, Termin termin) async {
    final index = _store.termine.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _store.termine[index] = Termin(
      id: id,
      trainerId: termin.trainerId,
      schuelerId: termin.schuelerId,
      pferdId: termin.pferdId,
      beginn: termin.beginn,
      ende: termin.ende,
      ort: termin.ort,
      typ: termin.typ,
      status: termin.status,
      notiz: termin.notiz,
    );
  }

  @override
  Future<void> statusAktualisieren(String id, TerminStatus status) async {
    final index = _store.termine.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final alt = _store.termine[index];
    _store.termine[index] = Termin(
      id: alt.id,
      trainerId: alt.trainerId,
      schuelerId: alt.schuelerId,
      pferdId: alt.pferdId,
      beginn: alt.beginn,
      ende: alt.ende,
      ort: alt.ort,
      typ: alt.typ,
      status: status,
      notiz: alt.notiz,
    );
  }
}
