import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../pferde/application/pferd_providers.dart';
import '../../termine/presentation/termin_form_screen.dart' show DateFormatDeAt;
import '../../trainer_schueler/application/trainer_schueler_providers.dart';
import '../application/trainingsplan_providers.dart';
import '../domain/schwaeche_model.dart';
import '../domain/trainingsplan_model.dart';
import '../domain/uebung_model.dart';

class _GeplanteEinheit {
  _GeplanteEinheit.ausUebung(this.uebung) : eigeneBezeichnung = null;
  _GeplanteEinheit.eigene(this.eigeneBezeichnung) : uebung = null;

  final Uebung? uebung;
  final String? eigeneBezeichnung;

  String get anzeigeName => uebung?.bezeichnung ?? eigeneBezeichnung ?? '';
}

/// Trainer-Wizard: Schüler wählen -> Zielschwächen wählen -> passende
/// Übungen laden (RPC `uebungen_fuer_nutzer`) -> Plan speichern.
class TrainingsplanErstellenScreen extends ConsumerStatefulWidget {
  const TrainingsplanErstellenScreen({super.key});

  @override
  ConsumerState<TrainingsplanErstellenScreen> createState() =>
      _TrainingsplanErstellenScreenState();
}

class _TrainingsplanErstellenScreenState
    extends ConsumerState<TrainingsplanErstellenScreen> {
  String? _schuelerId;
  String? _pferdId;
  final Set<String> _zielschwaecheIds = {};
  final List<_GeplanteEinheit> _einheiten = [];
  final _eigeneUebungController = TextEditingController();
  final _maxSchwierigkeitController = TextEditingController();
  final _disziplinController = TextEditingController();
  final _kommentarController = TextEditingController();

  DateTime _anfang = DateTime.now();
  DateTime _ende = DateTime.now().add(const Duration(days: 30));

  List<Uebung> _gefundeneUebungen = [];
  bool _wirdGesucht = false;
  bool _wirdGespeichert = false;
  String? _fehler;

  @override
  void dispose() {
    _eigeneUebungController.dispose();
    _maxSchwierigkeitController.dispose();
    _disziplinController.dispose();
    _kommentarController.dispose();
    super.dispose();
  }

  Future<void> _uebungenLaden() async {
    if (_schuelerId == null) return;
    setState(() {
      _wirdGesucht = true;
      _fehler = null;
    });
    try {
      final uebungen = await ref.read(trainingsplanRepositoryProvider).getUebungenFuerNutzer(
            nutzerId: _schuelerId!,
            maxSchwierigkeit: int.tryParse(_maxSchwierigkeitController.text.trim()),
            disziplin: _disziplinController.text.trim().isEmpty
                ? null
                : _disziplinController.text.trim(),
          );
      setState(() => _gefundeneUebungen = uebungen);
    } catch (e) {
      setState(() => _fehler = 'Übungen konnten nicht geladen werden: $e');
    } finally {
      if (mounted) setState(() => _wirdGesucht = false);
    }
  }

  void _uebungHinzufuegen(Uebung uebung) {
    setState(() => _einheiten.add(_GeplanteEinheit.ausUebung(uebung)));
  }

  void _eigeneUebungHinzufuegen() {
    final text = _eigeneUebungController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _einheiten.add(_GeplanteEinheit.eigene(text));
      _eigeneUebungController.clear();
    });
  }

  Future<void> _datumWaehlen({required bool istAnfang}) async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: istAnfang ? _anfang : _ende,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (gewaehlt == null) return;
    setState(() {
      if (istAnfang) {
        _anfang = gewaehlt;
        if (_ende.isBefore(_anfang)) _ende = _anfang.add(const Duration(days: 30));
      } else {
        _ende = gewaehlt;
      }
    });
  }

  Future<void> _planSpeichern(String trainerId) async {
    if (_schuelerId == null) {
      setState(() => _fehler = 'Bitte einen Schüler auswählen.');
      return;
    }
    if (_einheiten.isEmpty) {
      setState(() => _fehler = 'Bitte mindestens eine Übung zum Plan hinzufügen.');
      return;
    }
    if (_ende.isBefore(_anfang)) {
      setState(() => _fehler = 'Ende muss nach dem Anfang liegen.');
      return;
    }

    setState(() {
      _wirdGespeichert = true;
      _fehler = null;
    });

    final plan = Trainingsplan(
      nutzerId: _schuelerId!,
      trainerId: trainerId,
      pferdId: _pferdId,
      anfang: _anfang,
      ende: _ende,
      anzahlEinheiten: _einheiten.length,
      kommentar:
          _kommentarController.text.trim().isEmpty ? null : _kommentarController.text.trim(),
    );

    final einheiten = [
      for (var i = 0; i < _einheiten.length; i++)
        _erzeugeTrainingseinheit(_einheiten[i], reihenfolge: i + 1),
    ];

    try {
      await ref.read(trainingsplanRepositoryProvider).planErstellen(
            plan: plan,
            zielschwaecheIds: _zielschwaecheIds.toList(),
            einheiten: einheiten,
          );
      ref.invalidate(plaeneFuerTrainerProvider(trainerId));
      ref.invalidate(plaeneFuerSchuelerProvider(_schuelerId!));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Trainingsplan gespeichert.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _fehler = 'Speichern fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _wirdGespeichert = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainer = ref.watch(currentNutzerProvider).value;
    if (trainer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final schuelerAsync = ref.watch(aktiveSchuelerFuerTrainerProvider(trainer.id));
    final dateFormat = DateFormatDeAt();

    return Scaffold(
      appBar: AppBar(title: const Text('Trainingsplan erstellen')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('1. Schüler', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              schuelerAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Fehler: $e'),
                data: (eintraege) => DropdownButtonFormField<String>(
                  value: _schuelerId,
                  decoration: const InputDecoration(labelText: 'Schüler auswählen'),
                  items: eintraege
                      .map((e) => DropdownMenuItem(
                            value: e.gegenueber.id,
                            child: Text(e.gegenueber.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _schuelerId = value;
                    _pferdId = null;
                    _zielschwaecheIds.clear();
                    _einheiten.clear();
                    _gefundeneUebungen = [];
                  }),
                ),
              ),
              if (_schuelerId != null) ...[
                const SizedBox(height: 24),
                Text('2. Pferd (optional)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final pferdeAsync = ref.watch(pferdeFuerReiterProvider(_schuelerId!));
                    return pferdeAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Fehler: $e'),
                      data: (pferde) => DropdownButtonFormField<String?>(
                        value: _pferdId,
                        decoration: const InputDecoration(labelText: 'Pferd'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Kein Pferd')),
                          ...pferde.map(
                            (p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
                          ),
                        ],
                        onChanged: (value) => setState(() => _pferdId = value),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('3. Zielschwächen', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final schwaechenAsync = ref.watch(schwaechenFuerNutzerProvider(_schuelerId!));
                    return schwaechenAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Fehler: $e'),
                      data: (schwaechen) => _SchwaechenAuswahl(
                        schwaechen: schwaechen,
                        ausgewaehlt: _zielschwaecheIds,
                        onToggle: (id) => setState(() {
                          _zielschwaecheIds.contains(id)
                              ? _zielschwaecheIds.remove(id)
                              : _zielschwaecheIds.add(id);
                        }),
                      ),
                    );
                  },
                ),
                if (_pferdId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final pferdSchwaechenAsync =
                          ref.watch(schwaechenFuerPferdProvider(_pferdId!));
                      return pferdSchwaechenAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Fehler: $e'),
                        data: (schwaechen) => schwaechen.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _SchwaechenAuswahl(
                                  titel: 'Pferde-Schwächen',
                                  schwaechen: schwaechen,
                                  ausgewaehlt: _zielschwaecheIds,
                                  onToggle: (id) => setState(() {
                                    _zielschwaecheIds.contains(id)
                                        ? _zielschwaecheIds.remove(id)
                                        : _zielschwaecheIds.add(id);
                                  }),
                                ),
                              ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Text('4. Übungen', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxSchwierigkeitController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Max. Schwierigkeitsgrad'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _disziplinController,
                        decoration: const InputDecoration(labelText: 'Disziplin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _wirdGesucht ? null : _uebungenLaden,
                  child: const Text('Übungen laden'),
                ),
                if (_wirdGesucht) const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
                if (_gefundeneUebungen.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._gefundeneUebungen.map(
                    (uebung) => Card(
                      child: ListTile(
                        title: Text(uebung.bezeichnung),
                        subtitle: Text([
                          if (uebung.disziplin != null) uebung.disziplin!,
                          if (uebung.schwierigkeitsgrad != null)
                            'Schwierigkeit ${uebung.schwierigkeitsgrad}',
                        ].join(' · ')),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _uebungHinzufuegen(uebung),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _eigeneUebungController,
                        decoration:
                            const InputDecoration(labelText: 'Eigene Übung hinzufügen'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _eigeneUebungHinzufuegen,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('5. Plan-Einheiten (${_einheiten.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_einheiten.isEmpty)
                  const Text('Noch keine Übungen hinzugefügt.')
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _einheiten.length,
                    onReorder: (alt, neu) => setState(() {
                      if (neu > alt) neu -= 1;
                      final item = _einheiten.removeAt(alt);
                      _einheiten.insert(neu, item);
                    }),
                    itemBuilder: (context, index) {
                      final einheit = _einheiten[index];
                      return ListTile(
                        key: ValueKey('einheit_${index}_${einheit.anzeigeName}'),
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(einheit.anzeigeName),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _einheiten.removeAt(index)),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Text('6. Zeitraum', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anfang'),
                  subtitle: Text(dateFormat.format(_anfang)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _datumWaehlen(istAnfang: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ende'),
                  subtitle: Text(dateFormat.format(_ende)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _datumWaehlen(istAnfang: false),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _kommentarController,
                  decoration: const InputDecoration(labelText: 'Kommentar (optional)'),
                  maxLines: 3,
                ),
                if (_fehler != null) ...[
                  const SizedBox(height: 16),
                  Text(_fehler!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _wirdGespeichert ? null : () => _planSpeichern(trainer.id),
                  child: _wirdGespeichert
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Plan speichern'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Trainingseinheit _erzeugeTrainingseinheit(_GeplanteEinheit einheit, {required int reihenfolge}) {
  return einheit.uebung != null
      ? Trainingseinheit(uebungId: einheit.uebung!.id, reihenfolge: reihenfolge)
      : Trainingseinheit(eigeneUebung: einheit.eigeneBezeichnung!, reihenfolge: reihenfolge);
}

class _SchwaechenAuswahl extends StatelessWidget {
  const _SchwaechenAuswahl({
    this.titel,
    required this.schwaechen,
    required this.ausgewaehlt,
    required this.onToggle,
  });

  final String? titel;
  final List<Schwaeche> schwaechen;
  final Set<String> ausgewaehlt;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    if (schwaechen.isEmpty) {
      return const Text('Keine Schwächen hinterlegt.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(titel!, style: Theme.of(context).textTheme.labelLarge),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: schwaechen
              .map((s) => FilterChip(
                    label: Text(s.bezeichnung),
                    selected: ausgewaehlt.contains(s.id),
                    onSelected: (_) => onToggle(s.id),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
