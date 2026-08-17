import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/auth/auth_providers.dart';
import '../application/termin_providers.dart';
import '../domain/termin_model.dart';
import 'termin_form_screen.dart';

DateTime _tagOhneZeit(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Trainer-Kalenderansicht: Termine je Tag, Anlegen/Bearbeiten.
class TrainerKalenderScreen extends ConsumerStatefulWidget {
  const TrainerKalenderScreen({super.key});

  @override
  ConsumerState<TrainerKalenderScreen> createState() => _TrainerKalenderScreenState();
}

class _TrainerKalenderScreenState extends ConsumerState<TrainerKalenderScreen> {
  DateTime _fokussierterTag = DateTime.now();
  DateTime? _ausgewaehlterTag;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _ausgewaehlterTag = _tagOhneZeit(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final trainer = ref.watch(currentNutzerProvider).value;
    if (trainer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final termineAsync = ref.watch(termineFuerTrainerProvider(trainer.id));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TerminFormScreen(vorausgewaehlterTag: _ausgewaehlterTag),
            ),
          );
          ref.invalidate(termineFuerTrainerProvider(trainer.id));
        },
        child: const Icon(Icons.add),
      ),
      body: termineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (termine) {
          final termineProTag = <DateTime, List<Termin>>{};
          for (final termin in termine) {
            final tag = _tagOhneZeit(termin.beginn);
            termineProTag.putIfAbsent(tag, () => []).add(termin);
          }
          final termineAmTag = termineProTag[_ausgewaehlterTag] ?? const <Termin>[];

          return Column(
            children: [
              TableCalendar<Termin>(
                locale: 'de_DE',
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 730)),
                focusedDay: _fokussierterTag,
                calendarFormat: _format,
                selectedDayPredicate: (day) => isSameDay(_ausgewaehlterTag, day),
                eventLoader: (day) => termineProTag[_tagOhneZeit(day)] ?? const [],
                onFormatChanged: (format) => setState(() => _format = format),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _ausgewaehlterTag = _tagOhneZeit(selectedDay);
                    _fokussierterTag = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) => _fokussierterTag = focusedDay,
              ),
              const Divider(height: 1),
              Expanded(
                child: termineAmTag.isEmpty
                    ? const Center(child: Text('Keine Termine an diesem Tag.'))
                    : ListView.builder(
                        itemCount: termineAmTag.length,
                        itemBuilder: (context, index) {
                          final termin = termineAmTag[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(termin.typ?.isNotEmpty == true ? termin.typ! : 'Termin'),
                              subtitle: Text(
                                '${TimeOfDay.fromDateTime(termin.beginn).format(context)} – '
                                '${TimeOfDay.fromDateTime(termin.ende).format(context)}'
                                '${termin.ort != null ? ' · ${termin.ort}' : ''}',
                              ),
                              trailing: Chip(label: Text(termin.status.wert)),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TerminFormScreen(bearbeiten: termin),
                                  ),
                                );
                                ref.invalidate(termineFuerTrainerProvider(trainer.id));
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
