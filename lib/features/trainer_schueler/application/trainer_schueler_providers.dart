import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/trainer_schueler_repository.dart';
import '../domain/trainer_schueler_model.dart';

final trainerSchuelerRepositoryProvider = Provider<TrainerSchuelerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client != null
      ? SupabaseTrainerSchuelerRepository(client)
      : MockTrainerSchuelerRepository();
});

/// Alle Schüler-Verknüpfungen eines Trainers (jeder Status).
final schuelerFuerTrainerProvider =
    FutureProvider.family<List<TrainerSchuelerEintrag>, String>((ref, trainerId) {
  return ref.watch(trainerSchuelerRepositoryProvider).getSchuelerFuerTrainer(trainerId);
});

/// Nur aktive Schüler eines Trainers – Basis für Termin-/Planauswahl.
final aktiveSchuelerFuerTrainerProvider =
    FutureProvider.family<List<TrainerSchuelerEintrag>, String>((ref, trainerId) {
  return ref.watch(trainerSchuelerRepositoryProvider).getAktiveSchuelerFuerTrainer(trainerId);
});

/// Alle Trainer-Verknüpfungen eines Schülers (jeder Status).
final trainerFuerSchuelerProvider =
    FutureProvider.family<List<TrainerSchuelerEintrag>, String>((ref, schuelerId) {
  return ref.watch(trainerSchuelerRepositoryProvider).getTrainerFuerSchueler(schuelerId);
});
