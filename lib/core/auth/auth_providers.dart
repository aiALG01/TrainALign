import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/dev_config.dart';
import '../mock/mock_store.dart';
import '../supabase/supabase_providers.dart';
import 'auth_repository.dart';
import 'nutzer_model.dart';
import 'nutzer_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client != null ? SupabaseAuthRepository(client) : MockAuthRepository();
});

final nutzerRepositoryProvider = Provider<NutzerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client != null ? SupabaseNutzerRepository(client) : MockNutzerRepository();
});

/// App-weiter Auth-State (Login/Logout/Token-Refresh) als StreamProvider,
/// so wie im Auftrag gefordert.
///
/// Ist kein Supabase-Client verfügbar, gibt es keinen echten Auth-Stream –
/// dann wird sofort ein synthetischer "abgemeldet"-Zustand ausgegeben,
/// statt dauerhaft im Ladezustand zu hängen.
final authStateChangesProvider = StreamProvider<AuthState?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return Stream.value(null);
  }
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Die `nutzer`-Zeile des aktuell eingeloggten Users, `null` wenn nicht
/// eingeloggt oder wenn (noch) keine Zeile existiert (-> Onboarding).
///
/// Reagiert automatisch auf Login/Logout, da [authStateChangesProvider]
/// beobachtet wird. Nach dem Anlegen der Zeile im Onboarding muss dieser
/// Provider per `ref.invalidate(currentNutzerProvider)` neu geladen werden.
///
/// Im Dev-Bypass-Modus ([kDevBypassAuth]) wird direkt der Demo-Trainer aus
/// dem [MockStore] zurückgegeben, damit die komplette UI ohne Login
/// durchklickbar ist.
final currentNutzerProvider = FutureProvider<Nutzer?>((ref) async {
  if (kDevBypassAuth) {
    return MockStore.instance.nutzerMitId(MockStore.demoTrainerId);
  }

  ref.watch(authStateChangesProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return ref.watch(nutzerRepositoryProvider).getNutzer(user.id);
});
