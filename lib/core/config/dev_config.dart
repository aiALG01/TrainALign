/// Entwickler-Schalter für die UI-Vorschau ohne Backend.
///
/// `true`: Alle Auth-/Rollen-Redirects in go_router werden übersprungen,
/// die App startet direkt auf dem Trainer-Startscreen und sämtliche
/// Repositories liefern Mock-Daten (siehe [lib/core/mock/mock_store.dart]).
/// So lässt sich die komplette UI ohne Login und ohne Supabase-Verbindung
/// durchklicken.
///
/// Vor einem "echten" Release auf `false` setzen bzw. entfernen.
const bool kDevBypassAuth = true;
