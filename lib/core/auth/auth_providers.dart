import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';
import 'auth_repository.dart';
import 'nutzer_model.dart';
import 'nutzer_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final nutzerRepositoryProvider = Provider<NutzerRepository>((ref) {
  return NutzerRepository(ref.watch(supabaseClientProvider));
});

/// App-weiter Auth-State (Login/Logout/Token-Refresh) als StreamProvider,
/// so wie im Auftrag gefordert.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Die `nutzer`-Zeile des aktuell eingeloggten Users, `null` wenn nicht
/// eingeloggt oder wenn (noch) keine Zeile existiert (-> Onboarding).
///
/// Reagiert automatisch auf Login/Logout, da [authStateChangesProvider]
/// beobachtet wird. Nach dem Anlegen der Zeile im Onboarding muss dieser
/// Provider per `ref.invalidate(currentNutzerProvider)` neu geladen werden.
final currentNutzerProvider = FutureProvider<Nutzer?>((ref) async {
  ref.watch(authStateChangesProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return ref.watch(nutzerRepositoryProvider).getNutzer(user.id);
});
