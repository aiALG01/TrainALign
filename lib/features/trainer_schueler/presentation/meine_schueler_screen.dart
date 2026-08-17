import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../application/trainer_schueler_providers.dart';
import '../domain/trainer_schueler_model.dart';
import 'schueler_suche_screen.dart';

/// Übersicht des Trainers über alle verknüpften Schüler (jeder Status).
class MeineSchuelerScreen extends ConsumerWidget {
  const MeineSchuelerScreen({super.key});

  Color _statusFarbe(BuildContext context, TrainerSchuelerStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case TrainerSchuelerStatus.aktiv:
        return scheme.primaryContainer;
      case TrainerSchuelerStatus.angefragt:
        return scheme.secondaryContainer;
      case TrainerSchuelerStatus.beendet:
        return scheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainer = ref.watch(currentNutzerProvider).value;
    if (trainer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final eintraegeAsync = ref.watch(schuelerFuerTrainerProvider(trainer.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Schüler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SchuelerSucheScreen()),
          );
          ref.invalidate(schuelerFuerTrainerProvider(trainer.id));
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Schüler finden'),
      ),
      body: eintraegeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (eintraege) {
          if (eintraege.isEmpty) {
            return const Center(child: Text('Noch keine Schüler verknüpft.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(schuelerFuerTrainerProvider(trainer.id)),
            child: ListView.builder(
              itemCount: eintraege.length,
              itemBuilder: (context, index) {
                final eintrag = eintraege[index];
                return Card(
                  child: ListTile(
                    title: Text(eintrag.gegenueber.name),
                    subtitle: Text(eintrag.gegenueber.email),
                    trailing: Chip(
                      label: Text(eintrag.status.wert),
                      backgroundColor: _statusFarbe(context, eintrag.status),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
