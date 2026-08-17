import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../termine/presentation/termin_form_screen.dart' show DateFormatDeAt;
import '../application/trainingsplan_providers.dart';
import 'trainingsplan_detail_screen.dart';

/// Schüler-Ansicht: zugewiesene Trainingspläne, read-only.
class TrainingsplanListeScreen extends ConsumerWidget {
  const TrainingsplanListeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schueler = ref.watch(currentNutzerProvider).value;
    if (schueler == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final plaeneAsync = ref.watch(plaeneFuerSchuelerProvider(schueler.id));
    final dateFormat = DateFormatDeAt();

    return plaeneAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (plaene) {
        if (plaene.isEmpty) {
          return const Center(child: Text('Noch keine Trainingspläne zugewiesen.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(plaeneFuerSchuelerProvider(schueler.id)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plaene.length,
            itemBuilder: (context, index) {
              final plan = plaene[index];
              return Card(
                child: ListTile(
                  title: Text('${dateFormat.format(plan.anfang)} – ${dateFormat.format(plan.ende)}'),
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
    );
  }
}
