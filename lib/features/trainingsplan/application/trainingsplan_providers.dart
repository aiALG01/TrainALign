import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/trainingsplan_repository.dart';
import '../domain/schwaeche_model.dart';
import '../domain/trainingseinheit_bundle.dart';
import '../domain/trainingsplan_model.dart';

final trainingsplanRepositoryProvider = Provider<TrainingsplanRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client != null
      ? SupabaseTrainingsplanRepository(client)
      : MockTrainingsplanRepository();
});

final schwaechenFuerNutzerProvider =
    FutureProvider.family<List<Schwaeche>, String>((ref, nutzerId) {
  return ref.watch(trainingsplanRepositoryProvider).getSchwaechenFuerNutzer(nutzerId);
});

final schwaechenFuerPferdProvider =
    FutureProvider.family<List<Schwaeche>, String>((ref, pferdId) {
  return ref.watch(trainingsplanRepositoryProvider).getSchwaechenFuerPferd(pferdId);
});

final plaeneFuerSchuelerProvider =
    FutureProvider.family<List<Trainingsplan>, String>((ref, schuelerId) {
  return ref.watch(trainingsplanRepositoryProvider).getPlaeneFuerSchueler(schuelerId);
});

final plaeneFuerTrainerProvider =
    FutureProvider.family<List<Trainingsplan>, String>((ref, trainerId) {
  return ref.watch(trainingsplanRepositoryProvider).getPlaeneFuerTrainer(trainerId);
});

/// Lädt Einheiten + Zielschwächen eines Plans gebündelt für die
/// Detailansicht.
final planDetailProvider =
    FutureProvider.family<TrainingsplanDetailBundle, String>((ref, trainingsplanId) async {
  final repo = ref.watch(trainingsplanRepositoryProvider);
  final einheiten = await repo.getEinheitenFuerPlan(trainingsplanId);
  final zielschwaechen = await repo.getZielschwaechenFuerPlan(trainingsplanId);
  return TrainingsplanDetailBundle(einheiten: einheiten, zielschwaechen: zielschwaechen);
});
