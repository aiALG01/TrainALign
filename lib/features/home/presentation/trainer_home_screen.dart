import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../termine/presentation/trainer_kalender_screen.dart';
import '../../trainer_schueler/presentation/meine_schueler_screen.dart';
import '../../trainingsplan/presentation/trainer_plaene_screen.dart';

/// Startseite für Trainer mit Bottom-Navigation über die Kernfeatures.
class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  int _index = 0;

  static const _tabs = [
    _TrainerUebersichtTab(),
    TrainerKalenderScreen(),
    MeineSchuelerScreen(),
    TrainerPlaeneScreen(),
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
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Kalender'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Schüler'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Pläne'),
        ],
      ),
    );
  }
}

class _TrainerUebersichtTab extends ConsumerWidget {
  const _TrainerUebersichtTab();

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
