# TrainALign

Flutter-App für Reittrainer und deren Schüler. Backend: Supabase
(Auth, Postgres, Row Level Security). Dieser Stand deckt Funktion und
Architektur ab – das finale Branding/Moodboard folgt in einem späteren
Durchlauf.

## Stack

- Flutter (Dart), Ziel Android + iOS
- `supabase_flutter` (Auth + Postgres + RLS)
- Riverpod (State Management)
- `go_router` (rollenbasiert geschützte Navigation)
- `table_calendar` (Kalender-UI)

## Projektstruktur

```
lib/
  core/
    auth/       Nutzer-Model, Auth-/Nutzer-Repository, Riverpod-Provider
    router/     go_router-Instanz mit Redirect-Logik
    supabase/   Supabase-Client-Provider
    theme/      Ein zentrales ThemeData (austauschbare Farben/Schrift)
  features/
    auth/               Login, Registrierung
    onboarding/         Fallback: eingeloggt, aber keine nutzer-Zeile
    trainer_schueler/   Trainer↔Schüler-Verknüpfung
    termine/            Terminplanung (table_calendar)
    trainingsstunden/   Trainingsstunden-Dokumentation (Schüler)
    trainingsplan/      Trainingsplan-Erstellung (Trainer) & -Ansicht (Schüler)
    pferde/             Pferde-Repository (Support für andere Features)
    home/               Rollenbasierte Startseiten mit Bottom-Navigation
```

Jedes Feature kapselt seinen Datenzugriff in einem `data/`-Repository;
darüber liegen Riverpod-Provider in `application/`, die die
Presentation-Screens konsumieren.

## Datenbank

Die Supabase-Datenbank (inkl. Auth und RLS) existiert bereits. Diese App
legt keine Tabellen an und verändert kein Schema – sämtliche Zugriffe
laufen ausschließlich über `supabase_flutter` gegen die vorhandenen,
deutsch benannten Tabellen (`nutzer`, `trainer_schueler`, `pferd`,
`uebungen`, `kategorien`, `schwaechen`, `trainingsplan`, `termin`,
`trainingsstunde`, ...). Das Matching für die Planerstellung läuft über
die vorhandene RPC `uebungen_fuer_nutzer`.

## Setup

Supabase-Zugangsdaten werden ausschließlich über `--dart-define` injiziert
(nichts wird hardcodiert oder committet):

```bash
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Hinweis zu den Plattform-Ordnern

Dieses Repository enthält aktuell nur `lib/` und `pubspec.yaml` (die
Ausführungsumgebung, in der dieser Stand erstellt wurde, hat kein
Flutter-SDK installiert). Vor dem ersten Build lokal einmalig ausführen:

```bash
flutter create .
```

Das ergänzt die `android/`, `ios/` (sowie ggf. weitere Plattform-Ordner)
anhand von `pubspec.yaml`, ohne bestehenden Code in `lib/` zu verändern.
