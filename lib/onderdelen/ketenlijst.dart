// Lijst met ketens. Bovenaan de "bijna-ketens": daar is iedereen mee op één na.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/keten.dart';
import '../gegevens/opslag.dart';
import 'label.dart';
import 'vorm.dart';

class KetenLijst extends StatelessWidget {
  final void Function(Contact contact) onKies;
  final void Function(Keten keten) onToonKeten; // hele keten op de kaart tonen

  const KetenLijst({super.key, required this.onKies, required this.onToonKeten});

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
    // Open ketens: wie het verst staat, eerst.
    open.sort((a, b) => aandeelMee(b).compareTo(aandeelMee(a)));

    List<Widget> delen = [
      const Padding(
        padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
        child: Text(
          'Een keten is een chirurg met al zijn tandartsen en hun labo\'s.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    ];

    delen.add(titel('Bijna Bego (${bijna.length})', 'Iedereen is mee op één na. Eén bezoek maakt de keten volledig.'));
    if (bijna.isEmpty) delen.add(const Padding(padding: EdgeInsets.all(8), child: Text('Geen bijna-ketens.')));
    for (Keten keten in bijna) {
      delen.add(ketenKaart(keten));
    }

    delen.add(titel('Volledig Bego (${volledig.length})', 'Alle contacten in de keten gebruiken Bego.'));
    for (Keten keten in volledig) {
      delen.add(ketenKaart(keten));
    }

    delen.add(titel('Open (${open.length})', 'Twee of meer contacten zijn nog niet mee.'));
    for (Keten keten in open) {
      delen.add(ketenKaart(keten));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 96), children: delen);
  }

  // Bv. 3 van 4 mee = 0.75
  double aandeelMee(Keten keten) {
    return keten.aantalMee / keten.leden.length;
  }

  Widget titel(String tekst, String uitleg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tekst, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(uitleg, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget ketenKaart(Keten keten) {
    Color kleur = ketenStatusKleur(keten.status);

    List<Widget> inhoud = [
      // Kop: naam, status en knop "toon op kaart"
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Keten van ${keten.middelpunt.naam}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${keten.aantalMee} van ${keten.leden.length} gebruiken Bego',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
        ),
        Label(tekst: ketenStatusTekst(keten.status), kleur: kleur),
        IconButton(
          tooltip: 'Toon op kaart',
          icon: const Icon(Icons.map_outlined),
          onPressed: () => onToonKeten(keten),
        ),
      ]),
      const SizedBox(height: 8),
      // Voortgangsbalk
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: aandeelMee(keten),
          minHeight: 6,
          color: kleur,
          backgroundColor: Colors.grey.shade200,
        ),
      ),
      const SizedBox(height: 4),
    ];

    // De leden, per type: eerst chirurgen, dan tandartsen, dan labo's.
    for (Soort soort in Soort.values) {
      List<Contact> leden = keten.ledenVan(soort);
      if (leden.isEmpty) {
        inhoud.add(Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
          child: Text('Nog geen ${soortTekst(soort).toLowerCase()} gekend',
              style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
        ));
      }
      for (Contact lid in leden) {
        inhoud.add(lidRegel(keten, lid));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 4, 8), child: Column(children: inhoud)),
      ),
    );
  }

  Widget lidRegel(Keten keten, Contact lid) {
    Widget? rechts;
    if (lid.interesse != Interesse.gebruiktBego) {
      if (keten.status == KetenStatus.bijna) {
        rechts = const Label(tekst: 'Ontbreekt', kleur: Color(0xFFEF6C00));
      } else {
        rechts = const Label(tekst: 'Nog niet mee', kleur: Color(0xFF78909C));
      }
    }
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Vorm(soort: lid.soort, kleur: interesseKleur(lid.interesse), grootte: 18),
      title: Text(lid.naam, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${soortTekst(lid.soort)} · ${interesseTekst(lid.interesse)}'),
      trailing: rechts,
      onTap: () => onKies(lid),
    );
  }
}
