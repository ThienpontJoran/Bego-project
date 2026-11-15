// Formulier om een samenwerking (relatie) toe te voegen of aan te passen.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/opslag.dart';
import '../onderdelen/contact_regel.dart';
import '../onderdelen/kopje.dart';
import 'partner_kiezer.dart';
import 'venster.dart';

class RelatieFormulier extends StatefulWidget {
  final Contact contact;
  final Relatie? bestaand; // null = nieuwe relatie

  const RelatieFormulier({super.key, required this.contact, this.bestaand});

  @override
  State<RelatieFormulier> createState() => _RelatieFormulierState();
}

class _RelatieFormulierState extends State<RelatieFormulier> {
  Contact? partner;
  bool bevestigd = true;
  TextEditingController opmerking = TextEditingController();

  @override
  void initState() {
    super.initState();
    Relatie? bestaand = widget.bestaand;
    if (bestaand != null) {
      partner = bestaand.ander(widget.contact);
      bevestigd = bestaand.bevestigd;
      opmerking.text = bestaand.opmerking;
    }
  }

  Future<void> kiesPartner() async {
    List<Contact> uitsluiten = opslag.partnersVan(widget.contact);
    uitsluiten.add(widget.contact);
    dynamic gekozen = await toonVenster(
      context,
      PartnerKiezer(eigenSoort: widget.contact.soort, uitsluiten: uitsluiten),
    );
    if (gekozen is Contact) {
      setState(() => partner = gekozen);
    }
  }

  void opslaan() {
    opslag.voegRelatieToe(widget.contact, partner!, bevestigd: bevestigd, opmerking: opmerking.text.trim());
    opslag.bijgewerkt();
    Navigator.pop(context);
  }

  Future<void> verwijderen() async {
    bool zeker = await vraagBevestiging(context, 'Relatie verwijderen?', 'De lijn op de kaart verdwijnt.');
    if (!zeker || !mounted) return;
    opslag.verwijderRelatie(widget.bestaand!);
    opslag.bijgewerkt();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String titel = 'Partner toevoegen';
    if (widget.bestaand != null) titel = 'Relatie bewerken';

    void Function()? opslaanKnop;
    if (partner != null) opslaanKnop = opslaan; // pas opslaan als er een partner gekozen is

    List<Widget> velden = [
      kopje(context, '${widget.contact.naam} werkt samen met'),
    ];

    if (partner == null) {
      velden.add(OutlinedButton.icon(
        onPressed: kiesPartner,
        icon: const Icon(Icons.search),
        label: const Text('Kies een partner'),
      ));
    } else {
      Widget? wijzigKnop;
      if (widget.bestaand == null) {
        wijzigKnop = TextButton(onPressed: kiesPartner, child: const Text('Wijzig'));
      }
      velden.add(Card(child: ContactRegel(contact: partner!, onTap: () {}, rechts: wijzigKnop)));
    }

    velden.add(kopje(context, 'Zekerheid'));
    velden.add(SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('Bevestigd'), icon: Icon(Icons.check)),
        ButtonSegment(value: false, label: Text('Vermoed'), icon: Icon(Icons.help_outline)),
      ],
      selected: {bevestigd},
      onSelectionChanged: (keuze) => setState(() => bevestigd = keuze.first),
    ));
    velden.add(const Padding(
      padding: EdgeInsets.only(top: 6),
      child: Text('Een vermoede samenwerking is een stippellijn op de kaart.', style: TextStyle(color: Colors.grey)),
    ));

    velden.add(kopje(context, 'Opmerking'));
    velden.add(TextField(
      controller: opmerking,
      decoration: const InputDecoration(hintText: 'Bv. stuurt vooral sinusliften door'),
    ));

    if (widget.bestaand != null) {
      velden.add(const SizedBox(height: 24));
      velden.add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: verwijderen,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
          icon: const Icon(Icons.link_off),
          label: const Text('Relatie verwijderen'),
        ),
      ));
    }

    return Scaffold(
      appBar: formulierBalk(context, titel, opslaanKnop),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: velden),
    );
  }
}
