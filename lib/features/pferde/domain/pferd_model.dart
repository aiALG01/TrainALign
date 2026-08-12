/// Entspricht 1:1 der Tabelle `pferd`.
class Pferd {
  const Pferd({
    required this.id,
    required this.name,
    required this.reiterId,
    this.schwierigkeitsgrad,
    this.trainingshaeufigkeitWoechentlich,
  });

  factory Pferd.fromMap(Map<String, dynamic> map) {
    return Pferd(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      reiterId: map['reiter_id'] as String,
      schwierigkeitsgrad: map['schwierigkeitsgrad'] as int?,
      trainingshaeufigkeitWoechentlich: map['trainingshaeufigkeit_woechentlich'] as int?,
    );
  }

  final String id;
  final String name;
  final String reiterId;
  final int? schwierigkeitsgrad;
  final int? trainingshaeufigkeitWoechentlich;
}
