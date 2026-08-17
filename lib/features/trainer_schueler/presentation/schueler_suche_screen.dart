import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/nutzer_model.dart';
import '../application/trainer_schueler_providers.dart';

/// Trainer sucht Schüler per E-Mail/Name (`nutzer`) und legt eine
/// Verknüpfungsanfrage (`trainer_schueler`, status='angefragt') an.
class SchuelerSucheScreen extends ConsumerStatefulWidget {
  const SchuelerSucheScreen({super.key});

  @override
  ConsumerState<SchuelerSucheScreen> createState() => _SchuelerSucheScreenState();
}

class _SchuelerSucheScreenState extends ConsumerState<SchuelerSucheScreen> {
  final _suchController = TextEditingController();
  List<Nutzer> _ergebnisse = [];
  bool _wirdGesucht = false;
  String? _fehler;
  final Set<String> _angefragt = {};

  @override
  void dispose() {
    _suchController.dispose();
    super.dispose();
  }

  Future<void> _suchen() async {
    final begriff = _suchController.text.trim();
    if (begriff.isEmpty) {
      setState(() => _ergebnisse = []);
      return;
    }
    setState(() {
      _wirdGesucht = true;
      _fehler = null;
    });
    try {
      final ergebnisse = await ref.read(nutzerRepositoryProvider).sucheNutzer(
            suchbegriff: begriff,
            rolle: NutzerRolle.schueler,
          );
      setState(() => _ergebnisse = ergebnisse);
    } catch (e) {
      setState(() => _fehler = 'Suche fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _wirdGesucht = false);
    }
  }

  Future<void> _anfragen(Nutzer schueler) async {
    final trainer = ref.read(currentNutzerProvider).value;
    if (trainer == null) return;
    try {
      await ref.read(trainerSchuelerRepositoryProvider).anfrageErstellen(
            trainerId: trainer.id,
            schuelerId: schueler.id,
          );
      setState(() => _angefragt.add(schueler.id));
      ref.invalidate(schuelerFuerTrainerProvider(trainer.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anfrage an ${schueler.name} gesendet.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anfrage fehlgeschlagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schüler finden')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _suchController,
              decoration: const InputDecoration(
                labelText: 'Name oder E-Mail',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _suchen(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _wirdGesucht ? null : _suchen,
              child: const Text('Suchen'),
            ),
            if (_fehler != null) ...[
              const SizedBox(height: 8),
              Text(_fehler!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            if (_wirdGesucht) const Center(child: CircularProgressIndicator()),
            Expanded(
              child: ListView.builder(
                itemCount: _ergebnisse.length,
                itemBuilder: (context, index) {
                  final schueler = _ergebnisse[index];
                  final bereitsAngefragt = _angefragt.contains(schueler.id);
                  return Card(
                    child: ListTile(
                      title: Text(schueler.name),
                      subtitle: Text(schueler.email),
                      trailing: bereitsAngefragt
                          ? const Chip(label: Text('Angefragt'))
                          : TextButton(
                              onPressed: () => _anfragen(schueler),
                              child: const Text('Anfragen'),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
