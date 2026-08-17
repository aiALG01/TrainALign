import 'schwaeche_model.dart';
import 'trainingsplan_model.dart';

/// Bündelt Einheiten + Zielschwächen eines Plans für die Detailansicht.
class TrainingsplanDetailBundle {
  const TrainingsplanDetailBundle({required this.einheiten, required this.zielschwaechen});

  final List<Trainingseinheit> einheiten;
  final List<Schwaeche> zielschwaechen;
}
