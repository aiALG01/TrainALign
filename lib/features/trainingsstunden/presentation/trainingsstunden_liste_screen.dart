import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../termine/presentation/termin_form_screen.dart' show DateFormatDeAt;
import '../application/trainingsstunde_providers.dart';
import '../domain/trainingsstunde_model.dart';
import 'trainingsstunde_form_screen.dart';

enum _Filter { alle, mitTrainer, ohneTrainer }

/// Historienliste der eigenen Trainingsstunden, filterbar nach
/// mit/ohne Trainer.
class TrainingsstundenListeScreen extends ConsumerStatefulWidget {
  const TrainingsstundenListeScreen({super.key});

  @override
  ConsumerState<TrainingsstundenListeScreen> createState() =>
      _TrainingsstundenListeScreenState();
}

class _TrainingsstundenListeScreenState extends ConsumerState<TrainingsstundenListeScreen> {
  _Filter _filter = _Filter.alle;

  @override
  Widget build(BuildContext context) {
    final schueler = ref.watch(currentNutzerProvider).value;
    if (schueler == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stundenAsync = ref.watch(trainingsstundenFuerSchuelerProvider(schueler.id));
    final dateFormat = DateFormatDeAt();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TrainingsstundeFormScreen()),
          );
          ref.invalidate(trainingsstundenFuerSchuelerProvider(schueler.id));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.alle, label: Text('Alle')),
                ButtonSegment(value: _Filter.mitTrainer, label: Text('Mit Trainer')),
                ButtonSegment(value: _Filter.ohneTrainer, label: Text('Ohne Trainer')),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) => setState(() => _filter = selection.first),
            ),
          ),
          Expanded(
            child: stundenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Fehler: $error')),
              data: (stunden) {
                final gefiltert = stunden.where((s) {
                  switch (_filter) {
                    case _Filter.alle:
                      return true;
                    case _Filter.mitTrainer:
                      return s.mitTrainer;
                    case _Filter.ohneTrainer:
                      return !s.mitTrainer;
                  }
                }).toList();

                if (gefiltert.isEmpty) {
                  return const Center(child: Text('Keine Trainingsstunden vorhanden.'));
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(trainingsstundenFuerSchuelerProvider(schueler.id)),
                  child: ListView.builder(
                    itemCount: gefiltert.length,
                    itemBuilder: (context, index) {
                      final Trainingsstunde stunde = gefiltert[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            stunde.mitTrainer ? Icons.groups_outlined : Icons.person_outline,
                          ),
                          title: Text(dateFormat.format(stunde.datum)),
                          subtitle: Text(
                            '${stunde.dauerMinuten} Min.'
                            '${stunde.bewertung != null ? ' · Bewertung ${stunde.bewertung}' : ''}'
                            '${stunde.kommentar != null ? '\n${stunde.kommentar}' : ''}',
                          ),
                          isThreeLine: stunde.kommentar != null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
