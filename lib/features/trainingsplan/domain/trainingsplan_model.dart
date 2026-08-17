/// Entspricht 1:1 der Tabelle `trainingsplan`.
class Trainingsplan {
  const Trainingsplan({
    this.id,
    required this.nutzerId,
    required this.trainerId,
    this.pferdId,
    required this.anfang,
    required this.ende,
    this.anzahlEinheiten,
    this.bewertung,
    this.kommentar,
  });

  factory Trainingsplan.fromMap(Map<String, dynamic> map) {
    return Trainingsplan(
      id: map['id'] as String,
      nutzerId: map['nutzer_id'] as String,
      trainerId: map['trainer_id'] as String,
      pferdId: map['pferd_id'] as String?,
      anfang: DateTime.parse(map['anfang'] as String),
      ende: DateTime.parse(map['ende'] as String),
      anzahlEinheiten: map['anzahl_einheiten'] as int?,
      bewertung: map['bewertung'] as int?,
      kommentar: map['kommentar'] as String?,
    );
  }

  final String? id;
  final String nutzerId;
  final String trainerId;
  final String? pferdId;
  final DateTime anfang;
  final DateTime ende;
  final int? anzahlEinheiten;
  final int? bewertung;
  final String? kommentar;

  Map<String, dynamic> toInsertMap() {
    return {
      'nutzer_id': nutzerId,
      'trainer_id': trainerId,
      'pferd_id': pferdId,
      'anfang': anfang.toIso8601String(),
      'ende': ende.toIso8601String(),
      'anzahl_einheiten': anzahlEinheiten,
      'bewertung': bewertung,
      'kommentar': kommentar,
    };
  }
}

/// Entspricht 1:1 der Tabelle `trainingseinheit`.
class Trainingseinheit {
  const Trainingseinheit({
    this.id,
    this.trainingsplanId,
    this.uebungId,
    this.uebungBezeichnung,
    this.eigeneUebung,
    required this.reihenfolge,
    this.datum,
    this.bewertung,
    this.kommentar,
  }) : assert(
          uebungId != null || eigeneUebung != null,
          'Entweder uebungId oder eigeneUebung muss gesetzt sein',
        );

  factory Trainingseinheit.fromMap(Map<String, dynamic> map) {
    final uebung = map['uebung'] as Map<String, dynamic>?;
    return Trainingseinheit(
      id: map['id'] as String,
      trainingsplanId: map['trainingsplan_id'] as String?,
      uebungId: map['uebung_id'] as String?,
      uebungBezeichnung: uebung?['bezeichnung'] as String?,
      eigeneUebung: map['eigene_uebung'] as String?,
      reihenfolge: map['reihenfolge'] as int,
      datum: map['datum'] == null ? null : DateTime.parse(map['datum'] as String),
      bewertung: map['bewertung'] as int?,
      kommentar: map['kommentar'] as String?,
    );
  }

  final String? id;
  final String? trainingsplanId;
  final String? uebungId;

  /// Nur befüllt, wenn beim Laden über einen Join `uebung:uebung_id(bezeichnung)`
  /// mitgeladen wurde (siehe [TrainingsplanRepository.getEinheitenFuerPlan]).
  final String? uebungBezeichnung;
  final String? eigeneUebung;
  final int reihenfolge;
  final DateTime? datum;
  final int? bewertung;
  final String? kommentar;

  /// Anzeigename für die UI: eigene Übung, geladene Bezeichnung oder Fallback.
  String get anzeigeName => eigeneUebung ?? uebungBezeichnung ?? 'Übung';

  Map<String, dynamic> toInsertMap(String trainingsplanId) {
    return {
      'trainingsplan_id': trainingsplanId,
      'uebung_id': uebungId,
      'eigene_uebung': eigeneUebung,
      'reihenfolge': reihenfolge,
      'datum': datum?.toIso8601String(),
      'bewertung': bewertung,
      'kommentar': kommentar,
    };
  }
}
