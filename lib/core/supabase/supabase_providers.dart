import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ob `Supabase.initialize()` in `main()` erfolgreich war. Wird dort per
/// `ProviderScope(overrides: [...])` gesetzt. Solange kein Override erfolgt
/// (z. B. in Tests), wird von einer funktionierenden Verbindung ausgegangen.
final supabaseVerfuegbarProvider = Provider<bool>((ref) => true);

/// Der Supabase-Client, oder `null`, wenn die Initialisierung fehlgeschlagen
/// ist (fehlende Keys, ungültige Konfiguration, ...). Wird ebenfalls in
/// `main()` überschrieben.
///
/// Es wird bewusst NICHT `Supabase.instance.client` lazy in den
/// Repositories aufgerufen: Das würde bei fehlgeschlagener Initialisierung
/// synchron eine Exception werfen und – je nachdem, wo das im Widget-Baum
/// passiert – zu einem weißen Bildschirm ohne erkennbaren Fehler führen.
/// Stattdessen wird der (ggf. `null`) Client einmalig in main() ermittelt
/// und über Riverpod injiziert; alle Repository-Provider schalten anhand
/// von [supabaseVerfuegbarProvider] zwischen echter und Mock-Implementierung
/// um (siehe jeweils `application/*_providers.dart`).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);
