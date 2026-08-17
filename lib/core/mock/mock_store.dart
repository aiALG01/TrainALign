import '../auth/nutzer_model.dart';
import '../../features/pferde/domain/pferd_model.dart';
import '../../features/termine/domain/termin_model.dart';
import '../../features/trainer_schueler/domain/trainer_schueler_model.dart';
import '../../features/trainingsplan/domain/schwaeche_model.dart';
import '../../features/trainingsplan/domain/trainingsplan_model.dart';
import '../../features/trainingsplan/domain/uebung_model.dart';
import '../../features/trainingsstunden/domain/trainingsstunde_model.dart';

/// Verknüpfung `nutzer_schwaechen`/`pferd_schwaechen` als einfaches Tupel.
class MockZuordnung {
  const MockZuordnung(this.a, this.b);
  final String a;
  final String b;
}

/// In-Memory-"Datenbank" für den Demo-/Vorschau-Modus (kein Supabase
/// verfügbar bzw. `kDevBypassAuth`). Wird von allen Mock-Repositories
/// gemeinsam genutzt, damit z. B. ein im Wizard erstellter Trainingsplan
/// danach auch in der Schüler-Ansicht auftaucht.
///
/// Bewusst simpel gehalten (keine echten Foreign-Key-Constraints o. Ä.) –
/// dient ausschließlich dazu, die UI ohne Backend durchklickbar zu machen.
class MockStore {
  MockStore._() {
    _seed();
  }

  static final MockStore instance = MockStore._();

  int _idCounter = 1;
  String neueId(String praefix) => '$praefix-${_idCounter++}';

  late final List<Nutzer> nutzer;
  late final List<Pferd> pferde;
  final List<TrainerSchuelerEintrag> trainerSchueler = [];
  late final List<Schwaeche> schwaechen;
  final List<MockZuordnung> nutzerSchwaechen = [];
  final List<MockZuordnung> pferdSchwaechen = [];
  late final List<Uebung> uebungen;
  final List<Termin> termine = [];
  final List<Trainingsstunde> trainingsstunden = [];
  final List<Trainingsplan> trainingsplaene = [];
  final List<MockZuordnung> trainingsplanSchwaechen = [];
  final List<Trainingseinheit> trainingseinheiten = [];

  static const String demoTrainerId = 'mock-trainer-1';
  static const String demoSchuelerId = 'mock-schueler-1';

  Nutzer nutzerMitId(String id) => nutzer.firstWhere((n) => n.id == id);

  Uebung? uebungMitId(String? id) {
    if (id == null) return null;
    for (final u in uebungen) {
      if (u.id == id) return u;
    }
    return null;
  }

  void _seed() {
    nutzer = [
      const Nutzer(
        id: demoTrainerId,
        name: 'Anna Trainer',
        email: 'trainer@demo.dev',
        rolle: NutzerRolle.trainer,
      ),
      const Nutzer(
        id: demoSchuelerId,
        name: 'Lena Schülerin',
        email: 'lena@demo.dev',
        rolle: NutzerRolle.schueler,
      ),
      const Nutzer(
        id: 'mock-schueler-2',
        name: 'Max Mustermann',
        email: 'max@demo.dev',
        rolle: NutzerRolle.schueler,
      ),
      const Nutzer(
        id: 'mock-schueler-3',
        name: 'Julia Beispiel',
        email: 'julia@demo.dev',
        rolle: NutzerRolle.schueler,
      ),
    ];

    pferde = [
      const Pferd(
        id: 'mock-pferd-1',
        name: 'Luna',
        reiterId: demoSchuelerId,
        schwierigkeitsgrad: 3,
        trainingshaeufigkeitWoechentlich: 3,
      ),
      const Pferd(
        id: 'mock-pferd-2',
        name: 'Rocky',
        reiterId: 'mock-schueler-2',
        schwierigkeitsgrad: 2,
        trainingshaeufigkeitWoechentlich: 2,
      ),
    ];

    trainerSchueler.addAll([
      TrainerSchuelerEintrag(
        trainerId: demoTrainerId,
        schuelerId: demoSchuelerId,
        status: TrainerSchuelerStatus.aktiv,
        gegenueber: nutzerMitId(demoSchuelerId),
      ),
      TrainerSchuelerEintrag(
        trainerId: demoTrainerId,
        schuelerId: 'mock-schueler-2',
        status: TrainerSchuelerStatus.aktiv,
        gegenueber: nutzerMitId('mock-schueler-2'),
      ),
      TrainerSchuelerEintrag(
        trainerId: demoTrainerId,
        schuelerId: 'mock-schueler-3',
        status: TrainerSchuelerStatus.angefragt,
        gegenueber: nutzerMitId('mock-schueler-3'),
      ),
    ]);

    schwaechen = const [
      Schwaeche(
        id: 'mock-schwaeche-1',
        bezeichnung: 'Sitzstabilität',
        beschreibung: 'Unruhiger Sitz in schnelleren Gangarten',
        reiterSchwaeche: true,
      ),
      Schwaeche(
        id: 'mock-schwaeche-2',
        bezeichnung: 'Handeinwirkung',
        beschreibung: 'Zu feste Zügelführung',
        reiterSchwaeche: true,
      ),
      Schwaeche(
        id: 'mock-schwaeche-3',
        bezeichnung: 'Losgelassenheit',
        beschreibung: 'Pferd verspannt im Rücken',
        reiterSchwaeche: false,
      ),
    ];

    nutzerSchwaechen.addAll([
      const MockZuordnung(demoSchuelerId, 'mock-schwaeche-1'),
      const MockZuordnung(demoSchuelerId, 'mock-schwaeche-2'),
      const MockZuordnung('mock-schueler-2', 'mock-schwaeche-1'),
    ]);

    pferdSchwaechen.addAll([
      const MockZuordnung('mock-pferd-1', 'mock-schwaeche-3'),
    ]);

    uebungen = const [
      Uebung(
        id: 'mock-uebung-1',
        bezeichnung: 'Zirkel verkleinern und vergrößern',
        beschreibung: 'Fördert Balance und Sitzstabilität im Trab',
        schwierigkeitsgrad: 2,
        disziplin: 'Dressur',
        satz: '3x je Hand',
      ),
      Uebung(
        id: 'mock-uebung-2',
        bezeichnung: 'Stangenarbeit im Schritt',
        beschreibung: 'Verbessert Losgelassenheit und Trittsicherheit',
        schwierigkeitsgrad: 1,
        disziplin: 'Allgemein',
      ),
      Uebung(
        id: 'mock-uebung-3',
        bezeichnung: 'Übergänge Trab-Schritt-Trab',
        beschreibung: 'Trainiert weiche Handeinwirkung',
        schwierigkeitsgrad: 1,
        disziplin: 'Dressur',
        satz: '5x',
      ),
      Uebung(
        id: 'mock-uebung-4',
        bezeichnung: 'Leichttraben ohne Bügel',
        beschreibung: 'Stärkt den unabhängigen Sitz',
        schwierigkeitsgrad: 3,
        disziplin: 'Dressur',
      ),
    ];

    final heute = DateTime.now();
    final heuteOhneZeit = DateTime(heute.year, heute.month, heute.day);

    termine.addAll([
      Termin(
        id: 'mock-termin-1',
        trainerId: demoTrainerId,
        schuelerId: demoSchuelerId,
        pferdId: 'mock-pferd-1',
        beginn: heuteOhneZeit.add(const Duration(days: 1, hours: 10)),
        ende: heuteOhneZeit.add(const Duration(days: 1, hours: 11)),
        ort: 'Reithalle 1',
        typ: 'Einzelunterricht',
        status: TerminStatus.bestaetigt,
        notiz: 'Schwerpunkt Sitzstabilität',
      ),
      Termin(
        id: 'mock-termin-2',
        trainerId: demoTrainerId,
        schuelerId: 'mock-schueler-2',
        pferdId: 'mock-pferd-2',
        beginn: heuteOhneZeit.add(const Duration(days: 2, hours: 15)),
        ende: heuteOhneZeit.add(const Duration(days: 2, hours: 16)),
        ort: 'Außenplatz',
        typ: 'Einzelunterricht',
        status: TerminStatus.angefragt,
      ),
      Termin(
        id: 'mock-termin-3',
        trainerId: demoTrainerId,
        schuelerId: demoSchuelerId,
        pferdId: 'mock-pferd-1',
        beginn: heuteOhneZeit.subtract(const Duration(days: 3, hours: -9)),
        ende: heuteOhneZeit.subtract(const Duration(days: 3, hours: -10)),
        ort: 'Reithalle 1',
        typ: 'Longenunterricht',
        status: TerminStatus.abgesagt,
      ),
    ]);

    trainingsstunden.addAll([
      Trainingsstunde(
        id: 'mock-stunde-1',
        schuelerId: demoSchuelerId,
        trainerId: demoTrainerId,
        pferdId: 'mock-pferd-1',
        mitTrainer: true,
        datum: heuteOhneZeit.subtract(const Duration(days: 2)),
        dauerMinuten: 60,
        bewertung: 4,
        kommentar: 'Gute Fortschritte im Sitz.',
      ),
      Trainingsstunde(
        id: 'mock-stunde-2',
        schuelerId: demoSchuelerId,
        pferdId: 'mock-pferd-1',
        mitTrainer: false,
        datum: heuteOhneZeit.subtract(const Duration(days: 5)),
        dauerMinuten: 45,
      ),
    ]);

    trainingsplaene.add(
      Trainingsplan(
        id: 'mock-plan-1',
        nutzerId: demoSchuelerId,
        trainerId: demoTrainerId,
        pferdId: 'mock-pferd-1',
        anfang: heuteOhneZeit.subtract(const Duration(days: 7)),
        ende: heuteOhneZeit.add(const Duration(days: 23)),
        anzahlEinheiten: 2,
        kommentar: 'Fokus: Sitzstabilität und Handeinwirkung',
      ),
    );
    trainingsplanSchwaechen.addAll([
      const MockZuordnung('mock-plan-1', 'mock-schwaeche-1'),
      const MockZuordnung('mock-plan-1', 'mock-schwaeche-2'),
    ]);
    trainingseinheiten.addAll([
      const Trainingseinheit(
        id: 'mock-te-1',
        trainingsplanId: 'mock-plan-1',
        uebungId: 'mock-uebung-1',
        uebungBezeichnung: 'Zirkel verkleinern und vergrößern',
        reihenfolge: 1,
      ),
      const Trainingseinheit(
        id: 'mock-te-2',
        trainingsplanId: 'mock-plan-1',
        eigeneUebung: 'Aufwärmen im Schritt (10 Min.)',
        reihenfolge: 2,
      ),
    ]);
  }
}
