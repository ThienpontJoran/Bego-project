// Klein venster om de naam van een keten te veranderen.

import 'package:flutter/material.dart';

import '../gegevens/keten.dart';
import '../gegevens/opslag.dart';

Future<void> hernoemKeten(BuildContext context, Keten keten) async {
  TextEditingController invoer = TextEditingController(text: keten.naam);
  String standaard = 'Keten van ${keten.middelpunt.naam}';

  // Geeft de nieuwe naam terug, of null als je op "Annuleren" klikt.
  String? nieuweNaam = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Naam van de keten'),
        content: TextField(
          controller: invoer,
          autofocus: true,
          decoration: InputDecoration(hintText: standaard),
          onSubmitted: (tekst) => Navigator.pop(context, tekst),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Standaardnaam')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          FilledButton(onPressed: () => Navigator.pop(context, invoer.text), child: const Text('Opslaan')),
        ],
      );
    },
  );

  if (nieuweNaam == null) return; // geannuleerd
  opslag.zetKetenNaam(keten.middelpunt, nieuweNaam);
  opslag.bijgewerkt();
}
