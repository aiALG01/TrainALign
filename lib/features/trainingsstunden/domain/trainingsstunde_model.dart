/// Entspricht 1:1 der Tabelle `trainingsstunde`.
class Trainingsstunde {
  const Trainingsstunde({
    this.id,
    required this.schuelerId,
    this.trainerId,
    required this.pferdId,
    this.trainingsplanId,
    required this.mitTrainer,
    required this.datum,
    required this.dauerMinuten,
    this.bewertung,
    this.kommentar,
  });

  factory Trainingsstunde.fromMap(Map<String, dynamic> map) {
    return Trainingsstunde(
      id: map['id'] as String,
      schuelerId: map['schueler_id'] as String,
      trainerId: map['trainer_id'] as String?,
      pferdId: map['pferd_id'] as String,
      trainingsplanId: map['trainingsplan_id'] as String?,
      mitTrainer: map['mit_trainer'] as bool? ?? false,
      datum: DateTime.parse(map['datum'] as String),
      dauerMinuten: map['dauer_minuten'] as int,
      bewertung: map['bewertung'] as int?,
      kommentar: map['kommentar'] as String?,
    );
  }

  final String? id;
  final String schuelerId;
  final String? trainerId;
  final String pferdId;
  final String? trainingsplanId;
  final bool mitTrainer;
  final DateTime datum;
  final int dauerMinuten;
  final int? bewertung;
  final String? kommentar;

  Map<String, dynamic> toInsertMap() {
    return {
      'schueler_id': schuelerId,
      'trainer_id': trainerId,
      'pferd_id': pferdId,
      'trainingsplan_id': trainingsplanId,
      'mit_trainer': mitTrainer,
      'datum': datum.toIso8601String(),
      'dauer_minuten': dauerMinuten,
      'bewertung': bewertung,
      'kommentar': kommentar,
    };
  }
}

/// Schlanke Projektion von `trainingsplan` für die Auswahl beim Erfassen
/// einer Trainingsstunde (kein voller Domänen-Import aus dem
/// trainingsplan-Feature nötig).
class TrainingsplanKurz {
  const TrainingsplanKurz({required this.id, required this.anfang, required this.ende});

  factory TrainingsplanKurz.fromMap(Map<String, dynamic> map) {
    return TrainingsplanKurz(
      id: map['id'] as String,
      anfang: DateTime.parse(map['anfang'] as String),
      ende: DateTime.parse(map['ende'] as String),
    );
  }

  final String id;
  final DateTime anfang;
  final DateTime ende;
}
