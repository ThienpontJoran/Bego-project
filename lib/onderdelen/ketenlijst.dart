// Lijst met alle ketens. Bovenaan de ketens met de meeste Bego-gebruikers,
// onderaan de ketens waar nog niemand Bego gebruikt.

import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../models/keten.dart';
import '../services/opslag.dart';
import '../schermen/keten_naam_venster.dart';
import 'label.dart';
import 'vorm.dart';

class KetenLijst extends StatelessWidget {
  final void Function(Contact contact) onKies;
  final void Function(Keten keten) onToonKeten; // hele keten op de kaart tonen

  const KetenLijst({super.key, required this.onKies, required this.onToonKeten});

  @override
  Widget build(BuildContext context) {
    // Sorteren: meeste Bego-gebruikers bovenaan.
    // Evenveel? Dan eerst de keten waar het grootste deel mee is (3 van 3 voor 3 van 5).
    List<Keten> ketens = opslag.ketens;
    ketens.sort((a, b) {
      if (a.aantalMee != b.aantalMee) return b.aantalMee.compareTo(a.aantalMee);
      return aandeelMee(b).compareTo(aandeelMee(a));
    });

    List<Widget> delen = [
      const Padding(
        padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Text(
          "Een keten is een chirurg met al zijn tandartsen en hun labo's.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    ];
    if (ketens.isEmpty) {
      delen.add(const Padding(padding: EdgeInsets.all(8), child: Text('Nog geen ketens.')));
    }
    for (Keten keten in ketens) {
      delen.add(ketenKaart(context, keten));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 96), children: delen);
  }

  // Bv. 3 van 4 mee = 0.75
  double aandeelMee(Keten keten) {
    return keten.aantalMee / keten.leden.length;
  }

  Widget ketenKaart(BuildContext context, Keten keten) {
    Color kleur = ketenStatusKleur(keten.status);

    List<Widget> inhoud = [
      // Kop: naam, status en knop "toon op kaart"
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Klik op de naam (of het potloodje) om de keten een andere naam te geven.
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => hernoemKeten(context, keten),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: Text(keten.naam, style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(width: 6),
                const Tooltip(message: 'Naam wijzigen', child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey)),
              ]),
            ),
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
