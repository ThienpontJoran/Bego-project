// Het inlogscherm en de "poort" die beslist wat je ziet:
// niet ingelogd = inlogscherm, wel ingelogd = hoofdscherm.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/inlog_service.dart';
import 'hoofdscherm.dart';

class InlogPoort extends StatelessWidget {
  const InlogPoort({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder tekent opnieuw telkens als iemand in- of uitlogt.
    return StreamBuilder<AuthState>(
      stream: inlogService.veranderingen,
      builder: (context, snapshot) {
        if (inlogService.isIngelogd) return const Hoofdscherm();
        return const InlogScherm();
      },
    );
  }
}

class InlogScherm extends StatefulWidget {
  const InlogScherm({super.key});

  @override
  State<InlogScherm> createState() => _InlogSchermState();
}

class _InlogSchermState extends State<InlogScherm> {
  TextEditingController email = TextEditingController();
  TextEditingController wachtwoord = TextEditingController();
  bool bezig = false;
  String foutmelding = '';

  Future<void> inloggen() async {
    setState(() {
      bezig = true;
      foutmelding = '';
    });
    try {
      await inlogService.logIn(email.text.trim(), wachtwoord.text);
      // Gelukt: de InlogPoort toont nu vanzelf het hoofdscherm.
    } on AuthException {
      foutmelding = 'E-mailadres of wachtwoord klopt niet.';
    } catch (fout) {
      foutmelding = 'Inloggen lukt niet. Controleer je internet.';
    }
    if (!mounted) return;
    setState(() => bezig = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget knopTekst = const Text('Inloggen');
    if (bezig) {
      knopTekst = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AutofillGroup(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Icon(Icons.hub, size: 40, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Bego Netwerkkaart',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mailadres', prefixIcon: Icon(Icons.mail_outline)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: wachtwoord,
                      obscureText: true, // toont bolletjes in plaats van letters
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Wachtwoord', prefixIcon: Icon(Icons.lock_outline)),
                      onSubmitted: (tekst) => inloggen(), // Enter = inloggen
                    ),
                    if (foutmelding != '') ...[
                      const SizedBox(height: 12),
                      Text(foutmelding, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(onPressed: bezig ? null : inloggen, child: knopTekst),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
