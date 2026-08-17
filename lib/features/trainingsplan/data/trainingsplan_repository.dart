import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_store.dart';
import '../domain/schwaeche_model.dart';
import '../domain/trainingsplan_model.dart';
import '../domain/uebung_model.dart';

/// Kapselt sämtliche Zugriffe rund um Trainingsplan-Erstellung und -Ansicht:
/// `trainingsplan`, `trainingsplan_schwaeche`, `trainingseinheit`,
/// sowie die lesenden Joins über `nutzer_schwaechen`/`pferd_schwaechen`
/// -> `schwaechen` und den Aufruf der RPC `uebungen_fuer_nutzer`.
abstract class TrainingsplanRepository {
  /// Schwächen des Schülers: `nutzer_schwaechen` -> `schwaechen`.
  Future<List<Schwaeche>> getSchwaechenFuerNutzer(String nutzerId);

  /// Schwächen eines Pferds: `pferd_schwaechen` -> `schwaechen`.
  Future<List<Schwaeche>> getSchwaechenFuerPferd(String pferdId);

  /// Passende Übungen für den Schüler laden. Das Matching
  /// (nutzer_schwaechen -> schwaeche_kategorie -> kategorie_uebung ->
  /// uebungen) übernimmt ausschließlich die serverseitige RPC.
  Future<List<Uebung>> getUebungenFuerNutzer({
    required String nutzerId,
    int? maxSchwierigkeit,
    String? disziplin,
  });

  /// Speichert einen kompletten Plan: `trainingsplan` + Zielschwächen
  /// (`trainingsplan_schwaeche`) + Einheiten (`trainingseinheit`).
  Future<String> planErstellen({
    required Trainingsplan plan,
    required List<String> zielschwaecheIds,
    required List<Trainingseinheit> einheiten,
  });

  Future<List<Trainingsplan>> getPlaeneFuerSchueler(String schuelerId);

  Future<List<Trainingsplan>> getPlaeneFuerTrainer(String trainerId);

  Future<List<Trainingseinheit>> getEinheitenFuerPlan(String trainingsplanId);

  Future<List<Schwaeche>> getZielschwaechenFuerPlan(String trainingsplanId);
}

class SupabaseTrainingsplanRepository implements TrainingsplanRepository {
  SupabaseTrainingsplanRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Schwaeche>> getSchwaechenFuerNutzer(String nutzerId) async {
    final data = await _client
        .from('nutzer_schwaechen')
        .select('schwaeche:schwaeche_id(*)')
        .eq('nutzer_id', nutzerId);
    return (data as List)
        .map((row) => Schwaeche.fromMap(
              (row as Map<String, dynamic>)['schwaeche'] as Map<String, dynamic>,
            ))
        .toList();
  }

  @override
  Future<List<Schwaeche>> getSchwaechenFuerPferd(String pferdId) async {
    final data = await _client
        .from('pferd_schwaechen')
        .select('schwaeche:schwaeche_id(*)')
        .eq('pferd_id', pferdId);
    return (data as List)
        .map((row) => Schwaeche.fromMap(
              (row as Map<String, dynamic>)['schwaeche'] as Map<String, dynamic>,
            ))
        .toList();
  }

  @override
  Future<List<Uebung>> getUebungenFuerNutzer({
    required String nutzerId,
    int? maxSchwierigkeit,
    String? disziplin,
  }) async {
    final data = await _client.rpc('uebungen_fuer_nutzer', params: {
      'p_nutzer_id': nutzerId,
      'p_max_schwierigkeit': maxSchwierigkeit,
      'p_disziplin': disziplin,
    });
    return (data as List)
        .map((row) => Uebung.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> planErstellen({
    required Trainingsplan plan,
    required List<String> zielschwaecheIds,
    required List<Trainingseinheit> einheiten,
  }) async {
    final angelegterPlan = await _client
        .from('trainingsplan')
        .insert(plan.toInsertMap())
        .select('id')
        .single();
    final planId = angelegterPlan['id'] as String;

    if (zielschwaecheIds.isNotEmpty) {
      await _client.from('trainingsplan_schwaeche').insert([
        for (final schwaecheId in zielschwaecheIds)
          {'trainingsplan_id': planId, 'schwaeche_id': schwaecheId},
      ]);
    }

    if (einheiten.isNotEmpty) {
      await _client
          .from('trainingseinheit')
          .insert([for (final einheit in einheiten) einheit.toInsertMap(planId)]);
    }

    return planId;
  }

  @override
  Future<List<Trainingsplan>> getPlaeneFuerSchueler(String schuelerId) async {
    final data = await _client
        .from('trainingsplan')
        .select()
        .eq('nutzer_id', schuelerId)
        .order('anfang', ascending: false);
    return (data as List)
        .map((row) => Trainingsplan.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Trainingsplan>> getPlaeneFuerTrainer(String trainerId) async {
    final data = await _client
        .from('trainingsplan')
        .select()
        .eq('trainer_id', trainerId)
        .order('anfang', ascending: false);
    return (data as List)
        .map((row) => Trainingsplan.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Trainingseinheit>> getEinheitenFuerPlan(String trainingsplanId) async {
    final data = await _client
        .from('trainingseinheit')
        .select('*, uebung:uebung_id(bezeichnung)')
        .eq('trainingsplan_id', trainingsplanId)
        .order('reihenfolge');
    return (data as List)
        .map((row) => Trainingseinheit.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Schwaeche>> getZielschwaechenFuerPlan(String trainingsplanId) async {
    final data = await _client
        .from('trainingsplan_schwaeche')
        .select('schwaeche:schwaeche_id(*)')
        .eq('trainingsplan_id', trainingsplanId);
    return (data as List)
        .map((row) => Schwaeche.fromMap(
              (row as Map<String, dynamic>)['schwaeche'] as Map<String, dynamic>,
            ))
        .toList();
  }
}

/// Demo-/Vorschau-Modus: liest/verändert die geteilten [MockStore]-Daten.
/// Das Übungs-Matching der echten RPC wird hier stark vereinfacht durch
/// einen simplen Filter über Schwierigkeit/Disziplin nachgebildet.
class MockTrainingsplanRepository implements TrainingsplanRepository {
  final _store = MockStore.instance;

  @override
  Future<List<Schwaeche>> getSchwaechenFuerNutzer(String nutzerId) async {
    final ids = _store.nutzerSchwaechen
        .where((z) => z.a == nutzerId)
        .map((z) => z.b)
        .toSet();
    return _store.schwaechen.where((s) => ids.contains(s.id)).toList();
  }

  @override
  Future<List<Schwaeche>> getSchwaechenFuerPferd(String pferdId) async {
    final ids = _store.pferdSchwaechen
        .where((z) => z.a == pferdId)
        .map((z) => z.b)
        .toSet();
    return _store.schwaechen.where((s) => ids.contains(s.id)).toList();
  }

  @override
  Future<List<Uebung>> getUebungenFuerNutzer({
    required String nutzerId,
    int? maxSchwierigkeit,
    String? disziplin,
  }) async {
    return _store.uebungen.where((u) {
      final passtSchwierigkeit =
          maxSchwierigkeit == null || (u.schwierigkeitsgrad ?? 0) <= maxSchwierigkeit;
      final passtDisziplin = disziplin == null ||
          disziplin.trim().isEmpty ||
          (u.disziplin?.toLowerCase() == disziplin.trim().toLowerCase());
      return passtSchwierigkeit && passtDisziplin;
    }).toList();
  }

  @override
  Future<String> planErstellen({
    required Trainingsplan plan,
    required List<String> zielschwaecheIds,
    required List<Trainingseinheit> einheiten,
  }) async {
    final planId = _store.neueId('mock-plan');
    _store.trainingsplaene.add(
      Trainingsplan(
        id: planId,
        nutzerId: plan.nutzerId,
        trainerId: plan.trainerId,
        pferdId: plan.pferdId,
        anfang: plan.anfang,
        ende: plan.ende,
        anzahlEinheiten: plan.anzahlEinheiten,
        bewertung: plan.bewertung,
        kommentar: plan.kommentar,
      ),
    );
    for (final schwaecheId in zielschwaecheIds) {
      _store.trainingsplanSchwaechen.add(MockZuordnung(planId, schwaecheId));
    }
    for (final einheit in einheiten) {
      final uebung = _store.uebungMitId(einheit.uebungId);
      _store.trainingseinheiten.add(
        Trainingseinheit(
          id: _store.neueId('mock-te'),
          trainingsplanId: planId,
          uebungId: einheit.uebungId,
          uebungBezeichnung: uebung?.bezeichnung,
          eigeneUebung: einheit.eigeneUebung,
          reihenfolge: einheit.reihenfolge,
          datum: einheit.datum,
          bewertung: einheit.bewertung,
          kommentar: einheit.kommentar,
        ),
      );
    }
    return planId;
  }

  @override
  Future<List<Trainingsplan>> getPlaeneFuerSchueler(String schuelerId) async {
    return _store.trainingsplaene.where((p) => p.nutzerId == schuelerId).toList()
      ..sort((a, b) => b.anfang.compareTo(a.anfang));
  }

  @override
  Future<List<Trainingsplan>> getPlaeneFuerTrainer(String trainerId) async {
    return _store.trainingsplaene.where((p) => p.trainerId == trainerId).toList()
      ..sort((a, b) => b.anfang.compareTo(a.anfang));
  }

  @override
  Future<List<Trainingseinheit>> getEinheitenFuerPlan(String trainingsplanId) async {
    return _store.trainingseinheiten
        .where((e) => e.trainingsplanId == trainingsplanId)
        .toList()
      ..sort((a, b) => a.reihenfolge.compareTo(b.reihenfolge));
  }

  @override
  Future<List<Schwaeche>> getZielschwaechenFuerPlan(String trainingsplanId) async {
    final ids = _store.trainingsplanSchwaechen
        .where((z) => z.a == trainingsplanId)
        .map((z) => z.b)
        .toSet();
    return _store.schwaechen.where((s) => ids.contains(s.id)).toList();
  }
}
