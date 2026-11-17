// Formulier om een samenwerking (relatie) toe te voegen of aan te passen.

import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../models/relatie.dart';
import '../services/opslag.dart';
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
  Color? kleur; // null = standaard grijs
  TextEditingController opmerking = TextEditingController();

  @override
  void initState() {
    super.initState();
    Relatie? bestaand = widget.bestaand;
    if (bestaand != null) {
      partner = bestaand.ander(widget.contact);
      bevestigd = bestaand.bevestigd;
      kleur = bestaand.kleur;
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

  Future<void> opslaan() async {
    await opslag.voegRelatieToe(widget.contact, partner!,
        bevestigd: bevestigd, opmerking: opmerking.text.trim(), kleur: kleur);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> verwijderen() async {
    bool zeker = await vraagBevestiging(context, 'Relatie verwijderen?', 'De lijn op de kaart verdwijnt.');
    if (!zeker || !mounted) return;
    await opslag.verwijderRelatie(widget.bestaand!);
    if (!mounted) return;
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

    // Kleur van de lijn: een rij bolletjes, het eerste (grijs) is de standaard.
    velden.add(kopje(context, 'Kleur van de lijn'));
    List<Widget> bolletjes = [kleurBolletje(null)];
    for (Color mogelijkeKleur in lijnKleuren) {
      bolletjes.add(kleurBolletje(mogelijkeKleur));
    }
    velden.add(Wrap(spacing: 10, runSpacing: 10, children: bolletjes));

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

  // Eén rond bolletje om een kleur te kiezen. null = standaard (grijs).
  Widget kleurBolletje(Color? bolKleur) {
    bool gekozen = kleur == bolKleur;
    Color getoond = const Color(0xFF90A4AE);
    String uitleg = 'Standaard (grijs)';
    if (bolKleur != null) {
      getoond = bolKleur;
      uitleg = 'Deze kleur';
    }

    Widget? vinkje;
    if (gekozen) vinkje = const Icon(Icons.check, color: Colors.white, size: 20);

    return Tooltip(
      message: uitleg,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => kleur = bolKleur),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: getoond,
            shape: BoxShape.circle,
            border: Border.all(color: gekozen ? Colors.black87 : Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
          child: vinkje,
        ),
      ),
    );
  }
}
