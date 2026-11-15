// Hulpfuncties om een formulier of vraag te tonen.

import 'package:flutter/material.dart';

// Toont een formulier: op een gsm schermvullend, op een laptop als venster in het midden.
// Geeft terug wat het formulier meegeeft aan Navigator.pop(context, ...).
Future<dynamic> toonVenster(BuildContext context, Widget inhoud) {
  Size scherm = MediaQuery.of(context).size;

  if (scherm.width < 700) {
    return Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => inhoud,
    ));
  }

  double hoogte = scherm.height - 80;
  if (hoogte > 760) hoogte = 760;

  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(width: 560, height: hoogte, child: inhoud),
      );
    },
  );
}

// Vraagt "Ben je zeker?". Geeft true als de gebruiker op "Verwijderen" klikt.
Future<bool> vraagBevestiging(BuildContext context, String titel, String tekst) async {
  bool? antwoord = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(titel),
        content: Text(tekst),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
          ),
        ],
      );
    },
  );
  return antwoord == true;
}

// De bovenbalk van elk formulier: sluitknop, titel en een "Opslaan"-knop.
AppBar formulierBalk(BuildContext context, String titel, void Function()? opslaan, {bool bezig = false}) {
  Widget knopTekst = const Text('Opslaan');
  if (bezig) {
    knopTekst = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
  }
  return AppBar(
    title: Text(titel),
    leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: FilledButton(onPressed: opslaan, child: knopTekst),
      ),
    ],
  );
}
