// Het paneel met de gegevens van het aangeklikte contact.

import 'package:flutter/material.dart';

import 'contact.dart';
import 'vorm.dart';

class DetailPaneel extends StatelessWidget {
  final Contact contact;
  final List<Contact> partners;
  final void Function() sluiten;
  final void Function(Contact partner) kiesPartner;

  const DetailPaneel({
    super.key,
    required this.contact,
    required this.partners,
    required this.sluiten,
    required this.kiesPartner,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> regels = [];

    // Kop: icoon, naam en sluitknop
    regels.add(Row(
      children: [
        Vorm(soort: contact.soort, kleur: interesseKleur(contact.interesse), grootte: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(contact.naam, style: const TextStyle(fontSize: 22))),
        IconButton(onPressed: sluiten, icon: const Icon(Icons.close)),
      ],
    ));
    regels.add(Text('${soortTekst(contact.soort)} · ${interesseTekst(contact.interesse)}'));
    if (contact.praktijk != '') {
      regels.add(Text(contact.praktijk));
    }

    // Gegevens
    regels.add(const SizedBox(height: 12));
    regels.add(Text(contact.adres));
    if (contact.merk != '') {
      regels.add(Text('Huidig merk: ${contact.merk}'));
    }
    if (contact.opmerking != '') {
      regels.add(const SizedBox(height: 8));
      regels.add(Text(contact.opmerking, style: const TextStyle(fontStyle: FontStyle.italic)));
    }

    // Partners
    regels.add(const Divider(height: 24));
    regels.add(const Text('Partners', style: TextStyle(fontSize: 18)));
    if (partners.isEmpty) {
      regels.add(const Text('Nog geen partners'));
    }
    for (Contact partner in partners) {
      regels.add(ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Vorm(soort: partner.soort, kleur: interesseKleur(partner.interesse)),
        title: Text(partner.naam),
        subtitle: Text('${soortTekst(partner.soort)} · ${interesseTekst(partner.interesse)}'),
        onTap: () => kiesPartner(partner),
      ));
    }

    return Material(
      elevation: 4,
      child: ListView(padding: const EdgeInsets.all(16), children: regels),
    );
  }
}
