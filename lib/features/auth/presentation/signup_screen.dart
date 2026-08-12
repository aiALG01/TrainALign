import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/nutzer_model.dart';
import '../../../core/router/app_routes.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  NutzerRolle _rolle = NutzerRolle.schueler;
  bool _wirdGeladen = false;
  String? _fehler;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registrieren() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _wirdGeladen = true;
      _fehler = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    try {
      final response = await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: _passwordController.text,
          );

      final user = response.user;
      final hatSession = response.session != null;

      if (user != null && hatSession) {
        // Sofortige Session vorhanden -> nutzer-Zeile direkt anlegen.
        await ref.read(nutzerRepositoryProvider).nutzerAnlegen(
              id: user.id,
              name: name,
              email: email,
              rolle: _rolle,
            );
        ref.invalidate(currentNutzerProvider);
        // go_router-Redirect übernimmt die Weiterleitung zum Rollen-Home.
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrierung erfolgreich. Bitte bestätige deine E-Mail-Adresse '
              'und logge dich anschließend ein.',
            ),
          ),
        );
        context.go(AppRoutes.login);
      }
    } on AuthException catch (e) {
      setState(() => _fehler = e.message);
    } catch (e) {
      setState(() => _fehler = 'Registrierung fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _wirdGeladen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrieren')),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-Mail'),
                      validator: (value) => (value == null || !value.contains('@'))
                          ? 'Bitte gültige E-Mail eingeben'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Passwort'),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Mindestens 6 Zeichen'
                          : null,
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
                      onPressed: _wirdGeladen ? null : _registrieren,
                      child: _wirdGeladen
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrieren'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Schon ein Konto? Einloggen'),
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
