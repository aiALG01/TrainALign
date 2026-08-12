import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/nutzer_model.dart';

/// Wird angezeigt, wenn ein Nutzer eine gültige Session hat, aber (noch)
/// keine Zeile in `nutzer` existiert – z. B. weil die Registrierung eine
/// E-Mail-Bestätigung erforderte und die Zeile beim Signup nicht sofort
/// angelegt werden konnte.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  NutzerRolle _rolle = NutzerRolle.schueler;
  bool _wirdGeladen = false;
  String? _fehler;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _profilAnlegen() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || user.email == null) {
      setState(() => _fehler = 'Keine gültige Sitzung gefunden. Bitte erneut einloggen.');
      return;
    }

    setState(() {
      _wirdGeladen = true;
      _fehler = null;
    });

    try {
      await ref.read(nutzerRepositoryProvider).nutzerAnlegen(
            id: user.id,
            name: _nameController.text.trim(),
            email: user.email!,
            rolle: _rolle,
          );
      ref.invalidate(currentNutzerProvider);
      // go_router-Redirect übernimmt die Weiterleitung zum Rollen-Home.
    } catch (e) {
      setState(() => _fehler = 'Profil konnte nicht angelegt werden: $e');
    } finally {
      if (mounted) setState(() => _wirdGeladen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil vervollständigen'),
        actions: [
          IconButton(
            tooltip: 'Abmelden',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Fast geschafft! Bitte vervollständige dein Profil.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Ich bin...', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<NutzerRolle>(
                      segments: const [
                        ButtonSegment(
                          value: NutzerRolle.schueler,
                          label: Text('Schüler'),
                          icon: Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: NutzerRolle.trainer,
                          label: Text('Trainer'),
                          icon: Icon(Icons.sports_outlined),
                        ),
                      ],
                      selected: {_rolle},
                      onSelectionChanged: (selection) =>
                          setState(() => _rolle = selection.first),
                    ),
                    if (_fehler != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _fehler!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _wirdGeladen ? null : _profilAnlegen,
                      child: _wirdGeladen
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
        ),
      ),
    );
  }
}
