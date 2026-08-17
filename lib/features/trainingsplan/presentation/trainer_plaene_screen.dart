import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../termine/presentation/termin_form_screen.dart' show DateFormatDeAt;
import '../application/trainingsplan_providers.dart';
import 'trainingsplan_detail_screen.dart';
import 'trainingsplan_erstellen_screen.dart';

/// Trainer-Ansicht: selbst erstellte Trainingspläne + Erstellung neuer Pläne.
class TrainerPlaeneScreen extends ConsumerWidget {
  const TrainerPlaeneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainer = ref.watch(currentNutzerProvider).value;
    if (trainer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plaeneAsync = ref.watch(plaeneFuerTrainerProvider(trainer.id));
    final dateFormat = DateFormatDeAt();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TrainingsplanErstellenScreen()),
          );
          ref.invalidate(plaeneFuerTrainerProvider(trainer.id));
        },
        icon: const Icon(Icons.add),
        label: const Text('Neuer Plan'),
      ),
      body: plaeneAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (plaene) {
          if (plaene.isEmpty) {
            return const Center(child: Text('Noch keine Trainingspläne erstellt.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(plaeneFuerTrainerProvider(trainer.id)),
            child: ListView.builder(
              itemCount: plaene.length,
              itemBuilder: (context, index) {
                final plan = plaene[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      '${dateFormat.format(plan.anfang)} – ${dateFormat.format(plan.ende)}',
                    ),
                    subtitle: Text(
                      plan.anzahlEinheiten != null
                          ? '${plan.anzahlEinheiten} Einheiten'
                          : 'Trainingsplan',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TrainingsplanDetailScreen(plan: plan)),
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
