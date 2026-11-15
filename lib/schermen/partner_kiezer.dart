// Kies een bestaand contact als partner, of maak snel een nieuw aan.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/hulpfuncties.dart';
import '../gegevens/opslag.dart';
import '../onderdelen/contact_regel.dart';
import 'contact_formulier.dart';
import 'venster.dart';

class PartnerKiezer extends StatefulWidget {
  final Soort eigenSoort; // partners moeten van een ander type zijn
  final List<Contact> uitsluiten; // deze tonen we niet (bv. al gekozen)

  const PartnerKiezer({super.key, required this.eigenSoort, required this.uitsluiten});

  @override
  State<PartnerKiezer> createState() => _PartnerKiezerState();
}

class _PartnerKiezerState extends State<PartnerKiezer> {
  String zoekterm = '';

  Future<void> maakNieuw() async {
    // Een tandarts zoekt meestal een chirurg; de anderen meestal een tandarts.
    Soort startSoort = Soort.tandarts;
    if (widget.eigenSoort == Soort.tandarts) startSoort = Soort.chirurg;

    dynamic nieuw = await toonVenster(context, ContactFormulier(beginSoort: startSoort));
    if (!mounted) return;
    if (nieuw is Contact) Navigator.pop(context, nieuw);
  }

  @override
  Widget build(BuildContext context) {
    List<Contact> kandidaten = [];
    for (Contact contact in opslag.contacten) {
      if (contact.soort == widget.eigenSoort) continue;
      if (widget.uitsluiten.contains(contact)) continue;
      if (zoekterm.trim().length >= 2 && !pastBijZoekterm(contact, zoekterm)) continue;
      kandidaten.add(contact);
    }
    kandidaten.sort((a, b) => a.naam.compareTo(b.naam));

    List<Widget> regels = [
      ListTile(
        leading: CircleAvatar(child: Icon(Icons.person_add_alt_1, size: 20)),
        title: const Text('Nieuw contact aanmaken', style: TextStyle(fontWeight: FontWeight.w600)),
        onTap: maakNieuw,
      ),
      const Divider(),
    ];
    for (Contact contact in kandidaten) {
      regels.add(ContactRegel(contact: contact, onTap: () => Navigator.pop(context, contact)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kies een partner'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Zoek op naam, gemeente...', prefixIcon: Icon(Icons.search)),
            onChanged: (tekst) => setState(() => zoekterm = tekst),
          ),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: regels)),
      ]),
    );
  }
}
