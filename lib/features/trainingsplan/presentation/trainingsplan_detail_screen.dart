import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../termine/presentation/termin_form_screen.dart' show DateFormatDeAt;
import '../application/trainingsplan_providers.dart';
import '../domain/trainingsplan_model.dart';

/// Read-only Detailansicht eines Trainingsplans inkl. Einheiten und
/// Zielschwächen – für Schüler (und Trainer) gleichermaßen nutzbar.
class TrainingsplanDetailScreen extends ConsumerWidget {
  const TrainingsplanDetailScreen({super.key, required this.plan});

  final Trainingsplan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(planDetailProvider(plan.id!));
    final dateFormat = DateFormatDeAt();

    return Scaffold(
      appBar: AppBar(title: const Text('Trainingsplan')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (bundle) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${dateFormat.format(plan.anfang)} – ${dateFormat.format(plan.ende)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (plan.kommentar != null) ...[
                const SizedBox(height: 8),
                Text(plan.kommentar!),
              ],
              if (bundle.zielschwaechen.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Zielschwächen', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: bundle.zielschwaechen
                      .map((s) => Chip(label: Text(s.bezeichnung)))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              Text('Übungen', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (bundle.einheiten.isEmpty)
                const Text('Keine Einheiten hinterlegt.')
              else
                ...bundle.einheiten.map(
                  (einheit) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${einheit.reihenfolge}')),
                      title: Text(einheit.anzeigeName),
                      subtitle: einheit.kommentar != null ? Text(einheit.kommentar!) : null,
                      trailing:
                          einheit.bewertung != null ? Text('${einheit.bewertung}') : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
