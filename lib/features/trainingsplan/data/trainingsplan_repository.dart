import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/schwaeche_model.dart';
import '../domain/trainingsplan_model.dart';
import '../domain/uebung_model.dart';

/// Kapselt sämtliche Zugriffe rund um Trainingsplan-Erstellung und -Ansicht:
/// `trainingsplan`, `trainingsplan_schwaeche`, `trainingseinheit`,
/// sowie die lesenden Joins über `nutzer_schwaechen`/`pferd_schwaechen`
/// -> `schwaechen` und den Aufruf der RPC `uebungen_fuer_nutzer`.
class TrainingsplanRepository {
  TrainingsplanRepository(this._client);

  final SupabaseClient _client;

  /// Schwächen des Schülers: `nutzer_schwaechen` -> `schwaechen`.
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

  /// Schwächen eines Pferds: `pferd_schwaechen` -> `schwaechen`.
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

  /// Passende Übungen für den Schüler laden. Das Matching
  /// (nutzer_schwaechen -> schwaeche_kategorie -> kategorie_uebung ->
  /// uebungen) übernimmt ausschließlich die serverseitige RPC.
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

  /// Speichert einen kompletten Plan: `trainingsplan` + Zielschwächen
  /// (`trainingsplan_schwaeche`) + Einheiten (`trainingseinheit`).
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
