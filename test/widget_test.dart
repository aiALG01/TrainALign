import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reittrainer_app/core/supabase/supabase_providers.dart';
import 'package:reittrainer_app/main.dart';

void main() {
  testWidgets(
    'App startet im Demo-Modus (kein Supabase) ohne weißen Bildschirm und '
    'zeigt den Trainer-Startscreen',
    (tester) async {
      await initializeDateFormatting('de_DE');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseVerfuegbarProvider.overrideWithValue(false),
            supabaseClientProvider.overrideWithValue(null),
          ],
          child: const ReitTrainerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // kDevBypassAuth startet direkt auf dem Trainer-Startscreen mit dem
      // Mock-Nutzer aus dem MockStore – kein Login, keine echte
      // Supabase-Verbindung nötig. "Übersicht" erscheint sowohl als
      // AppBar-Titel als auch als Bottom-Nav-Label, daher findsWidgets.
      expect(find.text('Übersicht'), findsWidgets);
      expect(find.textContaining('Willkommen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
