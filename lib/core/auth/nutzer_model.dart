/// Rollen aus `nutzer.rolle`. Werte entsprechen exakt den DB-Werten.
enum NutzerRolle {
  trainer('trainer'),
  schueler('schueler');

  const NutzerRolle(this.wert);

  final String wert;

  static NutzerRolle fromWert(String wert) {
    return NutzerRolle.values.firstWhere(
      (r) => r.wert == wert,
      orElse: () => throw ArgumentError('Unbekannte Rolle: $wert'),
    );
  }
}

/// Entspricht 1:1 der Tabelle `nutzer`.
class Nutzer {
  const Nutzer({
    required this.id,
    required this.name,
    required this.email,
    required this.rolle,
    this.anzahlSchwaechen,
    this.schwierigkeitsgrad,
  });

  factory Nutzer.fromMap(Map<String, dynamic> map) {
    return Nutzer(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      rolle: NutzerRolle.fromWert(map['rolle'] as String),
      anzahlSchwaechen: map['anzahl_schwaechen'] as int?,
      schwierigkeitsgrad: map['schwierigkeitsgrad'] as int?,
    );
  }

  final String id;
  final String name;
  final String email;
  final NutzerRolle rolle;
  final int? anzahlSchwaechen;
  final int? schwierigkeitsgrad;

  bool get istTrainer => rolle == NutzerRolle.trainer;
  bool get istSchueler => rolle == NutzerRolle.schueler;
}
