/// Entspricht 1:1 der Tabelle `schwaechen`.
class Schwaeche {
  const Schwaeche({
    required this.id,
    required this.bezeichnung,
    this.beschreibung,
    required this.reiterSchwaeche,
  });

  factory Schwaeche.fromMap(Map<String, dynamic> map) {
    return Schwaeche(
      id: map['id'] as String,
      bezeichnung: map['bezeichnung'] as String? ?? '',
      beschreibung: map['beschreibung'] as String?,
      reiterSchwaeche: map['reiter_schwaeche'] as bool? ?? false,
    );
  }

  final String id;
  final String bezeichnung;
  final String? beschreibung;

  /// true = Schwäche des Reiters, false = Schwäche des Pferds.
  final bool reiterSchwaeche;
}
