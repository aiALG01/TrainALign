import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/trainingsstunde_repository.dart';
import '../domain/trainingsstunde_model.dart';

final trainingsstundeRepositoryProvider = Provider<TrainingsstundeRepository>((ref) {
  return TrainingsstundeRepository(ref.watch(supabaseClientProvider));
});

final trainingsstundenFuerSchuelerProvider =
    FutureProvider.family<List<Trainingsstunde>, String>((ref, schuelerId) {
  return ref.watch(trainingsstundeRepositoryProvider).getFuerSchueler(schuelerId);
});

final eigenePlaeneKurzProvider =
    FutureProvider.family<List<TrainingsplanKurz>, String>((ref, schuelerId) {
  return ref.watch(trainingsstundeRepositoryProvider).getEigenePlaeneKurz(schuelerId);
});
