/// Werte aus `termin.status`.
enum TerminStatus {
  angefragt('angefragt'),
  bestaetigt('bestaetigt'),
  abgesagt('abgesagt');

  const TerminStatus(this.wert);

  final String wert;

  static TerminStatus fromWert(String wert) {
    return TerminStatus.values.firstWhere(
      (s) => s.wert == wert,
      orElse: () => throw ArgumentError('Unbekannter Status: $wert'),
    );
  }
}

/// Entspricht 1:1 der Tabelle `termin`.
class Termin {
  const Termin({
    this.id,
    required this.trainerId,
    required this.schuelerId,
    this.pferdId,
    required this.beginn,
    required this.ende,
    this.ort,
    this.typ,
    required this.status,
    this.notiz,
  });

  factory Termin.fromMap(Map<String, dynamic> map) {
    return Termin(
      id: map['id'] as String,
      trainerId: map['trainer_id'] as String,
      schuelerId: map['schueler_id'] as String,
      pferdId: map['pferd_id'] as String?,
      beginn: DateTime.parse(map['beginn'] as String),
      ende: DateTime.parse(map['ende'] as String),
      ort: map['ort'] as String?,
      typ: map['typ'] as String?,
      status: TerminStatus.fromWert(map['status'] as String),
      notiz: map['notiz'] as String?,
    );
  }

  final String? id;
  final String trainerId;
  final String schuelerId;
  final String? pferdId;
  final DateTime beginn;
  final DateTime ende;
  final String? ort;
  final String? typ;
  final TerminStatus status;
  final String? notiz;

  Map<String, dynamic> toInsertMap() {
    return {
      'trainer_id': trainerId,
      'schueler_id': schuelerId,
      'pferd_id': pferdId,
      'beginn': beginn.toIso8601String(),
      'ende': ende.toIso8601String(),
      'ort': ort,
      'typ': typ,
      'status': status.wert,
      'notiz': notiz,
    };
  }
}
