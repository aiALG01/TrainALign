import '../../../core/auth/nutzer_model.dart';

/// Werte aus `trainer_schueler.status`.
enum TrainerSchuelerStatus {
  angefragt('angefragt'),
  aktiv('aktiv'),
  beendet('beendet');

  const TrainerSchuelerStatus(this.wert);

  final String wert;

  static TrainerSchuelerStatus fromWert(String wert) {
    return TrainerSchuelerStatus.values.firstWhere(
      (s) => s.wert == wert,
      orElse: () => throw ArgumentError('Unbekannter Status: $wert'),
    );
  }
}

/// Eine Zeile aus `trainer_schueler`, angereichert um den verknüpften
/// `nutzer`-Datensatz der Gegenseite (je nach Blickwinkel Trainer oder
/// Schüler), damit die UI Name/E-Mail direkt anzeigen kann.
class TrainerSchuelerEintrag {
  const TrainerSchuelerEintrag({
    required this.trainerId,
    required this.schuelerId,
    required this.status,
    required this.gegenueber,
  });

  factory TrainerSchuelerEintrag.fromMap(
    Map<String, dynamic> map, {
    required String gegenueberSchluessel,
  }) {
    return TrainerSchuelerEintrag(
      trainerId: map['trainer_id'] as String,
      schuelerId: map['schueler_id'] as String,
      status: TrainerSchuelerStatus.fromWert(map['status'] as String),
      gegenueber: Nutzer.fromMap(map[gegenueberSchluessel] as Map<String, dynamic>),
    );
  }

  final String trainerId;
  final String schuelerId;
  final TrainerSchuelerStatus status;

  /// Aus Trainer-Sicht: der Schüler. Aus Schüler-Sicht: der Trainer.
  final Nutzer gegenueber;
}
