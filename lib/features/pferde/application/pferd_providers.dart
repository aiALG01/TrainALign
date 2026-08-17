import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/pferd_repository.dart';
import '../domain/pferd_model.dart';

final pferdRepositoryProvider = Provider<PferdRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client != null ? SupabasePferdRepository(client) : MockPferdRepository();
});

final pferdeFuerReiterProvider =
    FutureProvider.family<List<Pferd>, String>((ref, reiterId) {
  return ref.watch(pferdRepositoryProvider).getPferdeFuerReiter(reiterId);
});
