import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../application/termin_providers.dart';
import '../domain/termin_model.dart';
import 'termin_form_screen.dart';

/// Schüler-Ansicht: eigene Termine, Status bestätigen/absagen.
class SchuelerTermineScreen extends ConsumerWidget {
  const SchuelerTermineScreen({super.key});

  Future<void> _statusAendern(
    WidgetRef ref,
    BuildContext context,
    Termin termin,
    TerminStatus neuerStatus,
    String schuelerId,
  ) async {
    try {
      await ref.read(terminRepositoryProvider).statusAktualisieren(termin.id!, neuerStatus);
      ref.invalidate(termineFuerSchuelerProvider(schuelerId));
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

    final termineAsync = ref.watch(termineFuerSchuelerProvider(schueler.id));
    final dateFormat = DateFormatDeAt();

    return termineAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (termine) {
        if (termine.isEmpty) {
          return const Center(child: Text('Keine Termine vorhanden.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(termineFuerSchuelerProvider(schueler.id)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: termine.length,
            itemBuilder: (context, index) {
              final termin = termine[index];
              return Card(
                child: ListTile(
                  title: Text(termin.typ?.isNotEmpty == true ? termin.typ! : 'Termin'),
                  subtitle: Text(
                    '${dateFormat.format(termin.beginn)} – ${dateFormat.format(termin.ende)}'
                    '${termin.ort != null ? '\n${termin.ort}' : ''}',
                  ),
                  isThreeLine: termin.ort != null,
                  trailing: termin.status == TerminStatus.angefragt
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Bestätigen',
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => _statusAendern(
                                ref,
                                context,
                                termin,
                                TerminStatus.bestaetigt,
                                schueler.id,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Absagen',
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: () => _statusAendern(
                                ref,
                                context,
                                termin,
                                TerminStatus.abgesagt,
                                schueler.id,
                              ),
                            ),
                          ],
                        )
                      : Chip(label: Text(termin.status.wert)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
