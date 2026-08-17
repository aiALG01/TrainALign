import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Kapselt sämtliche Supabase-Auth-Aufrufe (E-Mail/Passwort).
///
/// Interface, damit im Demo-/Vorschau-Modus (kein Supabase erreichbar) eine
/// [MockAuthRepository] eingesetzt werden kann, ohne dass Aufrufer davon
/// wissen müssen (siehe `auth_providers.dart`).
abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;

  Session? get currentSession;

  User? get currentUser;

  Future<AuthResponse> signUp({required String email, required String password});

  Future<AuthResponse> signIn({required String email, required String password});

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

/// Demo-/Vorschau-Modus: kein Backend vorhanden. Es existiert nie eine
/// Session; Anmeldeversuche schlagen mit einer verständlichen Meldung fehl
/// (relevant nur, falls [kDevBypassAuth] aus deaktiviert ist und die
/// Login-/Signup-Screens tatsächlich erreicht werden).
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Future<AuthResponse> signUp({required String email, required String password}) {
    throw const AuthException(
      'Demo-Modus ohne Supabase-Verbindung: Registrierung nicht möglich.',
    );
  }

  @override
  Future<AuthResponse> signIn({required String email, required String password}) {
    throw const AuthException(
      'Demo-Modus ohne Supabase-Verbindung: Login nicht möglich.',
    );
  }

  @override
  Future<void> signOut() async {}
}
