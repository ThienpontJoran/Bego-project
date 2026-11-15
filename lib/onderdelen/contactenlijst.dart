// Lijst met contacten (resultaat van zoeken en filters).

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/hulpfuncties.dart';
import 'contact_regel.dart';

class ContactenLijst extends StatelessWidget {
  final List<Contact> contacten;
  final Contact? gekozen;
  final void Function(Contact contact) onKies;

  const ContactenLijst({super.key, required this.contacten, required this.gekozen, required this.onKies});

  @override
  Widget build(BuildContext context) {
    if (contacten.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Geen contacten gevonden', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Pas je zoekterm of filters aan.', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
    }

    // Alfabetisch sorteren (een kopie, zodat de echte lijst niet verandert).
    List<Contact> gesorteerd = List.of(contacten);
    gesorteerd.sort((a, b) => a.naam.compareTo(b.naam));

    List<Widget> regels = [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Text('${gesorteerd.length} contacten', style: const TextStyle(color: Colors.grey)),
      ),
    ];
    for (Contact contact in gesorteerd) {
      regels.add(ContactRegel(
        contact: contact,
        gekozen: contact == gekozen,
        onTap: () => onKies(contact),
        rechts: laatsteBezoekTekst(contact),
      ));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(8, 0, 8, 96), children: regels);
  }

  Widget laatsteBezoekTekst(Contact contact) {
    Bezoek? laatste = contact.laatsteBezoek;
    String tekst = 'nooit bezocht';
    if (laatste != null) tekst = geledenTekst(laatste.datum);

    Color kleur = Colors.grey;
    if (contact.langNietBezocht) kleur = const Color(0xFFE65100);
    return Text(tekst, style: TextStyle(fontSize: 12, color: kleur));
  }
}
