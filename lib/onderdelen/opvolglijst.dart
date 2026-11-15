// Opvolging: geplande volgende stappen en wie lang niet bezocht is.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/hulpfuncties.dart';
import '../gegevens/opslag.dart';
import 'contact_regel.dart';

class OpvolgLijst extends StatelessWidget {
  final void Function(Contact contact) onKies;

  const OpvolgLijst({super.key, required this.onKies});

  @override
  Widget build(BuildContext context) {
    // Contacten waarvan het laatste bezoek een volgende stap heeft.
    List<Contact> metStap = [];
    // Contacten die langer dan 3 maanden niet bezocht zijn.
    List<Contact> langNiet = [];

    for (Contact contact in opslag.contacten) {
      Bezoek? laatste = contact.laatsteBezoek;
      if (laatste != null && laatste.volgendeStap != '') metStap.add(contact);
      if (contact.langNietBezocht) langNiet.add(contact);
    }
    metStap.sort(vergelijkStapDatum);
    langNiet.sort(vergelijkLangNiet);

    List<Widget> delen = [];

    delen.add(titel('Volgende stappen (${metStap.length})'));
    if (metStap.isEmpty) delen.add(leeg('Geen geplande stappen.'));
    for (Contact contact in metStap) {
      Bezoek laatste = contact.laatsteBezoek!;
      delen.add(ContactRegel(
        contact: contact,
        onTap: () => onKies(contact),
        onderschrift: laatste.volgendeStap,
        rechts: stapDatum(laatste.volgendeStapDatum),
      ));
    }

    delen.add(titel('Lang niet bezocht (${langNiet.length})'));
    if (langNiet.isEmpty) delen.add(leeg('Iedereen is recent bezocht.'));
    for (Contact contact in langNiet) {
      String tekst = 'Nog nooit bezocht';
      Bezoek? laatste = contact.laatsteBezoek;
      if (laatste != null) tekst = 'Laatst: ${geledenTekst(laatste.datum)}';
      delen.add(ContactRegel(contact: contact, onTap: () => onKies(contact), onderschrift: tekst));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(8, 0, 8, 96), children: delen);
  }

  // Vroegste datum eerst; stappen zonder datum achteraan.
  int vergelijkStapDatum(Contact a, Contact b) {
    DateTime? datumA = a.laatsteBezoek!.volgendeStapDatum;
    DateTime? datumB = b.laatsteBezoek!.volgendeStapDatum;
    if (datumA == null && datumB == null) return 0;
    if (datumA == null) return 1;
    if (datumB == null) return -1;
    return datumA.compareTo(datumB);
  }

  // Nooit bezocht eerst, daarna het langst geleden.
  int vergelijkLangNiet(Contact a, Contact b) {
    int dagenA = a.dagenNietBezocht ?? 100000; // ?? = "als het null is, neem dan..."
    int dagenB = b.dagenNietBezocht ?? 100000;
    return dagenB.compareTo(dagenA);
  }

  Widget stapDatum(DateTime? datum) {
    if (datum == null) return const SizedBox();
    bool telaat = datum.isBefore(vandaag());
    Color kleur = Colors.grey.shade700;
    if (telaat) kleur = const Color(0xFFD32F2F);
    return Text(datumTekst(datum), style: TextStyle(fontSize: 12, color: kleur, fontWeight: FontWeight.w600));
  }

  Widget titel(String tekst) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(tekst, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  Widget leeg(String tekst) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(tekst, style: const TextStyle(color: Colors.grey)),
    );
  }
}
