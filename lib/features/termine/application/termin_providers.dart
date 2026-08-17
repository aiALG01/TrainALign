import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/termin_repository.dart';
import '../domain/termin_model.dart';

final terminRepositoryProvider = Provider<TerminRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client != null ? SupabaseTerminRepository(client) : MockTerminRepository();
});

final termineFuerTrainerProvider =
    FutureProvider.family<List<Termin>, String>((ref, trainerId) {
  return ref.watch(terminRepositoryProvider).getTermineFuerTrainer(trainerId);
});

final termineFuerSchuelerProvider =
    FutureProvider.family<List<Termin>, String>((ref, schuelerId) {
  return ref.watch(terminRepositoryProvider).getTermineFuerSchueler(schuelerId);
});
