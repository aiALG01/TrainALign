import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../termine/presentation/schueler_termine_screen.dart';
import '../../trainer_schueler/presentation/trainer_anfragen_screen.dart';
import '../../trainingsplan/presentation/trainingsplan_liste_screen.dart';
import '../../trainingsstunden/presentation/trainingsstunden_liste_screen.dart';

/// Startseite für Schüler mit Bottom-Navigation über die Kernfeatures.
class SchuelerHomeScreen extends StatefulWidget {
  const SchuelerHomeScreen({super.key});

  @override
  State<SchuelerHomeScreen> createState() => _SchuelerHomeScreenState();
}

class _SchuelerHomeScreenState extends State<SchuelerHomeScreen> {
  int _index = 0;

  static const _tabs = [
    _SchuelerUebersichtTab(),
    _TabMitAppBar(titel: 'Meine Termine', kind: TrainingsplanTabKind.termine),
    _TabMitAppBar(titel: 'Trainingsstunden', kind: TrainingsplanTabKind.stunden),
    _TabMitAppBar(titel: 'Trainingspläne', kind: TrainingsplanTabKind.plaene),
    _TabMitAppBar(titel: 'Meine Trainer', kind: TrainingsplanTabKind.trainer),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Übersicht'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Termine'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Stunden'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Pläne'),
          NavigationDestination(icon: Icon(Icons.sports_outlined), label: 'Trainer'),
        ],
      ),
    );
  }
}

enum TrainingsplanTabKind { termine, stunden, plaene, trainer }

/// Gemeinsame AppBar-Hülle für die Tabs ohne eigenen Scaffold.
class _TabMitAppBar extends StatelessWidget {
  const _TabMitAppBar({required this.titel, required this.kind});

  final String titel;
  final TrainingsplanTabKind kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titel)),
      body: switch (kind) {
        TrainingsplanTabKind.termine => const SchuelerTermineScreen(),
        TrainingsplanTabKind.stunden => const TrainingsstundenListeScreen(),
        TrainingsplanTabKind.plaene => const TrainingsplanListeScreen(),
        TrainingsplanTabKind.trainer => const TrainerAnfragenScreen(),
      },
    );
  }
}

class _SchuelerUebersichtTab extends ConsumerWidget {
  const _SchuelerUebersichtTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutzerAsync = ref.watch(currentNutzerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Übersicht'),
        actions: [
          IconButton(
            tooltip: 'Abmelden',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: nutzerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (nutzer) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Willkommen, ${nutzer?.name ?? ''}!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}
