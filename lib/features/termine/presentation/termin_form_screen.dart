import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../pferde/application/pferd_providers.dart';
import '../../trainer_schueler/application/trainer_schueler_providers.dart';
import '../application/termin_providers.dart';
import '../domain/termin_model.dart';

/// Trainer legt einen Termin mit einem (aktiven) Schüler an oder
/// bearbeitet einen bestehenden.
class TerminFormScreen extends ConsumerStatefulWidget {
  const TerminFormScreen({super.key, this.bearbeiten, this.vorausgewaehlterTag});

  /// Vorhandener Termin zum Bearbeiten, oder `null` für Neuanlage.
  final Termin? bearbeiten;

  /// Vorbelegter Tag beim Neuanlegen aus der Kalenderansicht.
  final DateTime? vorausgewaehlterTag;

  @override
  ConsumerState<TerminFormScreen> createState() => _TerminFormScreenState();
}

class _TerminFormScreenState extends ConsumerState<TerminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ortController = TextEditingController();
  final _typController = TextEditingController();
  final _notizController = TextEditingController();

  String? _schuelerId;
  String? _pferdId;
  late DateTime _beginn;
  late DateTime _ende;
  TerminStatus _status = TerminStatus.angefragt;
  bool _wirdGespeichert = false;
  String? _fehler;

  bool get _istBearbeitung => widget.bearbeiten != null;

  @override
  void initState() {
    super.initState();
    final vorlage = widget.bearbeiten;
    if (vorlage != null) {
      _schuelerId = vorlage.schuelerId;
      _pferdId = vorlage.pferdId;
      _beginn = vorlage.beginn;
      _ende = vorlage.ende;
      _status = vorlage.status;
      _ortController.text = vorlage.ort ?? '';
      _typController.text = vorlage.typ ?? '';
      _notizController.text = vorlage.notiz ?? '';
    } else {
      final tag = widget.vorausgewaehlterTag ?? DateTime.now();
      _beginn = DateTime(tag.year, tag.month, tag.day, 9);
      _ende = _beginn.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _ortController.dispose();
    _typController.dispose();
    _notizController.dispose();
    super.dispose();
  }

  Future<void> _datumZeitWaehlen({required bool istBeginn}) async {
    final aktuell = istBeginn ? _beginn : _ende;
    final datum = await showDatePicker(
      context: context,
      initialDate: aktuell,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (datum == null || !mounted) return;
    final zeit = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(aktuell),
    );
    if (zeit == null) return;
    final neu = DateTime(datum.year, datum.month, datum.day, zeit.hour, zeit.minute);
    setState(() {
      if (istBeginn) {
        _beginn = neu;
        if (_ende.isBefore(_beginn)) {
          _ende = _beginn.add(const Duration(hours: 1));
        }
      } else {
        _ende = neu;
      }
    });
  }

  Future<void> _speichern(String trainerId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_schuelerId == null) {
      setState(() => _fehler = 'Bitte einen Schüler auswählen.');
      return;
    }
    if (_ende.isBefore(_beginn)) {
      setState(() => _fehler = 'Ende muss nach dem Beginn liegen.');
      return;
    }

    setState(() {
      _wirdGespeichert = true;
      _fehler = null;
    });

    final termin = Termin(
      trainerId: trainerId,
      schuelerId: _schuelerId!,
      pferdId: _pferdId,
      beginn: _beginn,
      ende: _ende,
      ort: _ortController.text.trim().isEmpty ? null : _ortController.text.trim(),
      typ: _typController.text.trim().isEmpty ? null : _typController.text.trim(),
      status: _status,
      notiz: _notizController.text.trim().isEmpty ? null : _notizController.text.trim(),
    );

    try {
      final repo = ref.read(terminRepositoryProvider);
      if (_istBearbeitung) {
        await repo.aktualisieren(widget.bearbeiten!.id!, termin);
      } else {
        await repo.anlegen(termin);
      }
      ref.invalidate(termineFuerTrainerProvider(trainerId));
      ref.invalidate(termineFuerSchuelerProvider(_schuelerId!));
      if (mounted) Navigator.of(context).pop();
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
      appBar: AppBar(title: Text(_istBearbeitung ? 'Termin bearbeiten' : 'Neuer Termin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                schuelerAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Schüler konnten nicht geladen werden: $e'),
                  data: (eintraege) => DropdownButtonFormField<String>(
                    value: _schuelerId,
                    decoration: const InputDecoration(labelText: 'Schüler'),
                    items: eintraege
                        .map((e) => DropdownMenuItem(
                              value: e.gegenueber.id,
                              child: Text(e.gegenueber.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _schuelerId = value;
                      _pferdId = null;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                if (_schuelerId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final pferdeAsync = ref.watch(pferdeFuerReiterProvider(_schuelerId!));
                      return pferdeAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Pferde konnten nicht geladen werden: $e'),
                        data: (pferde) => DropdownButtonFormField<String?>(
                          value: _pferdId,
                          decoration: const InputDecoration(labelText: 'Pferd (optional)'),
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
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Beginn'),
                  subtitle: Text(dateFormat.format(_beginn)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _datumZeitWaehlen(istBeginn: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ende'),
                  subtitle: Text(dateFormat.format(_ende)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _datumZeitWaehlen(istBeginn: false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ortController,
                  decoration: const InputDecoration(labelText: 'Ort'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typController,
                  decoration: const InputDecoration(labelText: 'Typ (z. B. Einzelunterricht)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notizController,
                  decoration: const InputDecoration(labelText: 'Notiz'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TerminStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: TerminStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.wert)))
                      .toList(),
                  onChanged: (value) => setState(() => _status = value ?? _status),
                ),
                if (_fehler != null) ...[
                  const SizedBox(height: 16),
                  Text(_fehler!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _wirdGespeichert ? null : () => _speichern(trainer.id),
                  child: _wirdGespeichert
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Speichern'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kleiner, abhängigkeitsfreier Datum/Zeit-Formatter (dd.MM.yyyy HH:mm).
class DateFormatDeAt {
  String format(DateTime dt) {
    String zwei(int n) => n.toString().padLeft(2, '0');
    return '${zwei(dt.day)}.${zwei(dt.month)}.${dt.year} ${zwei(dt.hour)}:${zwei(dt.minute)}';
  }
}
