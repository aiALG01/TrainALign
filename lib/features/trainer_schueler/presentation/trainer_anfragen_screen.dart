import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../application/trainer_schueler_providers.dart';
import '../domain/trainer_schueler_model.dart';

/// Schüler-Ansicht: eigene Trainer-Verknüpfungen, Anfragen bestätigen/ablehnen.
class TrainerAnfragenScreen extends ConsumerWidget {
  const TrainerAnfragenScreen({super.key});

  Future<void> _statusAendern(
    WidgetRef ref,
    BuildContext context,
    TrainerSchuelerEintrag eintrag,
    TrainerSchuelerStatus neuerStatus,
  ) async {
    try {
      await ref.read(trainerSchuelerRepositoryProvider).statusAktualisieren(
            trainerId: eintrag.trainerId,
            schuelerId: eintrag.schuelerId,
            status: neuerStatus,
          );
      ref.invalidate(trainerFuerSchuelerProvider(eintrag.schuelerId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Aktion fehlgeschlagen: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schueler = ref.watch(currentNutzerProvider).value;
    if (schueler == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final eintraegeAsync = ref.watch(trainerFuerSchuelerProvider(schueler.id));

    return eintraegeAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (eintraege) {
        if (eintraege.isEmpty) {
          return const Center(child: Text('Noch keine Trainer-Anfragen.'));
        }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(trainerFuerSchuelerProvider(schueler.id)),
            child: ListView.builder(
              itemCount: eintraege.length,
              itemBuilder: (context, index) {
                final eintrag = eintraege[index];
                return Card(
                  child: ListTile(
                    title: Text(eintrag.gegenueber.name),
                    subtitle: Text(eintrag.gegenueber.email),
                    trailing: eintrag.status == TrainerSchuelerStatus.angefragt
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Bestätigen',
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => _statusAendern(
                                  ref,
                                  context,
                                  eintrag,
                                  TrainerSchuelerStatus.aktiv,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Ablehnen',
                                icon: const Icon(Icons.cancel_outlined),
                                onPressed: () => _statusAendern(
                                  ref,
                                  context,
                                  eintrag,
                                  TrainerSchuelerStatus.beendet,
                                ),
                              ),
                            ],
                          )
                        : Chip(label: Text(eintrag.status.wert)),
                  ),
                );
              },
            ),
          );
        },
    );
  }
}
