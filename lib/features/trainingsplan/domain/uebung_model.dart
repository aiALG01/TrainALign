/// Entspricht 1:1 der Tabelle `uebungen` (bzw. dem Rückgabeformat der RPC
/// `uebungen_fuer_nutzer`, die dieselben Spalten liefert).
class Uebung {
  const Uebung({
    required this.id,
    required this.bezeichnung,
    this.beschreibung,
    this.kategorieId,
    this.schwierigkeitsgrad,
    this.ersteller,
    this.satz,
    this.disziplin,
  });

  factory Uebung.fromMap(Map<String, dynamic> map) {
    return Uebung(
      id: map['id'] as String,
      bezeichnung: map['bezeichnung'] as String? ?? '',
      beschreibung: map['beschreibung'] as String?,
      kategorieId: map['kategorie_id'] as String?,
      schwierigkeitsgrad: map['schwierigkeitsgrad'] as int?,
      ersteller: map['ersteller'] as String?,
      satz: map['satz'] as String?,
      disziplin: map['disziplin'] as String?,
    );
  }

  final String id;
  final String bezeichnung;
  final String? beschreibung;
  final String? kategorieId;
  final int? schwierigkeitsgrad;
  final String? ersteller;
  final String? satz;
  final String? disziplin;
}
