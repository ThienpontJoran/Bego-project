// Lijst met ketens. Bovenaan de "bijna-ketens": daar ontbreekt nog één schakel.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/keten.dart';
import '../gegevens/opslag.dart';
import 'label.dart';
import 'vorm.dart';

class KetenLijst extends StatelessWidget {
  final void Function(Contact contact) onKies;

  const KetenLijst({super.key, required this.onKies});

  @override
  Widget build(BuildContext context) {
    List<Keten> bijna = [];
    List<Keten> volledig = [];
    List<Keten> open = [];
    for (Keten keten in opslag.ketens) {
      if (keten.status == KetenStatus.bijna) bijna.add(keten);
      if (keten.status == KetenStatus.volledig) volledig.add(keten);
      if (keten.status == KetenStatus.open) open.add(keten);
    }

    List<Widget> delen = [];

    delen.add(titel('Bijna Bego (${bijna.length})',
        'Twee van de drie zijn al mee. Eén bezoek kan de keten volledig maken.'));
    if (bijna.isEmpty) delen.add(const Padding(padding: EdgeInsets.all(8), child: Text('Geen bijna-ketens.')));
    for (Keten keten in bijna) {
      delen.add(ketenKaart(context, keten));
    }

    delen.add(titel('Volledig Bego (${volledig.length})', 'Chirurg, tandarts en labo gebruiken alle drie Bego.'));
    for (Keten keten in volledig) {
      delen.add(ketenKaart(context, keten));
    }

    // De open ketens zitten in een uitklapbaar blok, want dat zijn er vaak veel.
    List<Widget> openKaarten = [];
    for (Keten keten in open) {
      openKaarten.add(ketenKaart(context, keten));
    }
    delen.add(const SizedBox(height: 8));
    delen.add(ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: const Border(),
      title: Text('Open (${open.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Eén of geen enkele schakel is mee.'),
      children: openKaarten,
    ));

    return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 96), children: delen);
  }

  Widget titel(String tekst, String uitleg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tekst, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(uitleg, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget ketenKaart(BuildContext context, Keten keten) {
    List<Widget> regels = [];
    for (Contact lid in keten.leden) {
      Widget? rechts;
      if (keten.status == KetenStatus.bijna && lid.interesse != Interesse.gebruiktBego) {
        rechts = const Label(tekst: 'Ontbreekt', kleur: Color(0xFFEF6C00));
      }
      regels.add(ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Vorm(soort: lid.soort, kleur: interesseKleur(lid.interesse), grootte: 18),
        title: Text(lid.naam, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${soortTekst(lid.soort)} · ${interesseTekst(lid.interesse)}'),
        trailing: rechts,
        onTap: () => onKies(lid),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(padding: const EdgeInsets.all(4), child: Column(children: regels)),
      ),
    );
  }
}
