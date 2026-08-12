import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../pferde/application/pferd_providers.dart';
import '../../termine/presentation/termin_form_screen.dart' show DateFormatDeAt;
import '../application/trainingsstunde_providers.dart';
import '../domain/trainingsstunde_model.dart';

/// Schüler erfasst eine absolvierte Trainingsstunde.
class TrainingsstundeFormScreen extends ConsumerStatefulWidget {
  const TrainingsstundeFormScreen({super.key});

  @override
  ConsumerState<TrainingsstundeFormScreen> createState() =>
      _TrainingsstundeFormScreenState();
}

class _TrainingsstundeFormScreenState extends ConsumerState<TrainingsstundeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dauerController = TextEditingController();
  final _bewertungController = TextEditingController();
  final _kommentarController = TextEditingController();

  String? _pferdId;
  String? _trainingsplanId;
  bool _mitTrainer = false;
  DateTime _datum = DateTime.now();
  bool _wirdGespeichert = false;
  String? _fehler;

  @override
  void dispose() {
    _dauerController.dispose();
    _bewertungController.dispose();
    _kommentarController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now(),
    );
    if (gewaehlt != null) setState(() => _datum = gewaehlt);
  }

  Future<void> _speichern(String schuelerId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pferdId == null) {
      setState(() => _fehler = 'Bitte ein Pferd auswählen.');
      return;
    }

    setState(() {
      _wirdGespeichert = true;
      _fehler = null;
    });

    final stunde = Trainingsstunde(
      schuelerId: schuelerId,
      pferdId: _pferdId!,
      trainingsplanId: _trainingsplanId,
      mitTrainer: _mitTrainer,
      datum: _datum,
      dauerMinuten: int.parse(_dauerController.text.trim()),
      bewertung: _bewertungController.text.trim().isEmpty
          ? null
          : int.tryParse(_bewertungController.text.trim()),
      kommentar: _kommentarController.text.trim().isEmpty
          ? null
          : _kommentarController.text.trim(),
    );

    try {
      await ref.read(trainingsstundeRepositoryProvider).anlegen(stunde);
      ref.invalidate(trainingsstundenFuerSchuelerProvider(schuelerId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _fehler = 'Speichern fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _wirdGespeichert = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schueler = ref.watch(currentNutzerProvider).value;
    if (schueler == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pferdeAsync = ref.watch(pferdeFuerReiterProvider(schueler.id));
    final plaeneAsync = ref.watch(eigenePlaeneKurzProvider(schueler.id));
    final dateFormat = DateFormatDeAt();

    return Scaffold(
      appBar: AppBar(title: const Text('Trainingsstunde erfassen')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                pferdeAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Pferde konnten nicht geladen werden: $e'),
                  data: (pferde) => DropdownButtonFormField<String>(
                    initialValue: _pferdId,
                    decoration: const InputDecoration(labelText: 'Pferd'),
                    items: pferde
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _pferdId = value),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mit Trainer'),
                  value: _mitTrainer,
                  onChanged: (value) => setState(() => _mitTrainer = value),
                ),
                const SizedBox(height: 8),
                plaeneAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Trainingspläne konnten nicht geladen werden: $e'),
                  data: (plaene) => DropdownButtonFormField<String?>(
                    initialValue: _trainingsplanId,
                    decoration: const InputDecoration(labelText: 'Trainingsplan (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Kein Plan')),
                      ...plaene.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text('${dateFormat.format(p.anfang)} – ${dateFormat.format(p.ende)}'),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _trainingsplanId = value),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Datum'),
                  subtitle: Text(dateFormat.format(_datum)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _datumWaehlen,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dauerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dauer (Minuten)'),
                  validator: (value) {
                    final n = int.tryParse(value?.trim() ?? '');
                    return (n == null || n <= 0) ? 'Bitte eine gültige Dauer angeben' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bewertungController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bewertung (optional)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
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
                  onPressed: _wirdGespeichert ? null : () => _speichern(schueler.id),
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
