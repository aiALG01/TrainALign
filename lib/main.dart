import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_providers.dart';
import 'core/theme/app_theme.dart';

/// Supabase-Zugangsdaten werden ausschließlich über --dart-define injiziert,
/// z. B.:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Es wird nichts hardcodiert oder committet.
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');

  // Supabase.initialize() bewusst NICHT ungefangen lassen: Fehlen die Keys
  // oder ist die Konfiguration ungültig, soll die App trotzdem starten
  // (Demo-/Vorschau-Modus mit Mock-Daten statt weißem Bildschirm/Absturz).
  SupabaseClient? client;
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
      client = Supabase.instance.client;
    } catch (error, stackTrace) {
      debugPrint('Supabase-Initialisierung fehlgeschlagen, Demo-Modus aktiv: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  } else {
    debugPrint(
      'SUPABASE_URL/SUPABASE_ANON_KEY fehlen – App startet im Demo-Modus mit Mock-Daten. '
      'Für echten Backend-Zugriff mit --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=... starten.',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        supabaseVerfuegbarProvider.overrideWithValue(client != null),
        supabaseClientProvider.overrideWithValue(client),
      ],
      child: const ReitTrainerApp(),
    ),
  );
}

class ReitTrainerApp extends ConsumerWidget {
  const ReitTrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ReitTrainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
