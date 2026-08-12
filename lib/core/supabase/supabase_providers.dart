import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Zugriff auf den global initialisierten Supabase-Client (siehe [main.dart]).
///
/// Der Client wird ausschließlich über [Supabase.initialize] mit
/// SUPABASE_URL/SUPABASE_ANON_KEY aus --dart-define aufgesetzt. Hier wird er
/// lediglich für die Riverpod-Provider-Graph zugänglich gemacht.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
