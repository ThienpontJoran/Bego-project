// Formulier om een contact toe te voegen of te bewerken.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../gegevens/adres_zoeker.dart';
import '../gegevens/contact.dart';
import '../gegevens/opslag.dart';
import '../onderdelen/interesse_kiezer.dart';
import '../onderdelen/kopje.dart';
import '../onderdelen/vorm.dart';
import 'partner_kiezer.dart';
import 'venster.dart';

class ContactFormulier extends StatefulWidget {
  final Contact? bestaand; // null = nieuw contact
  final Soort beginSoort;

  const ContactFormulier({super.key, this.bestaand, this.beginSoort = Soort.tandarts});

  @override
  State<ContactFormulier> createState() => _ContactFormulierState();
}

class _ContactFormulierState extends State<ContactFormulier> {
  // Met deze sleutel kunnen we alle velden in één keer controleren.
  final GlobalKey<FormState> formulierSleutel = GlobalKey<FormState>();

  // Een controller onthoudt wat er in een tekstvak staat.
  TextEditingController naam = TextEditingController();
  TextEditingController praktijk = TextEditingController();
  TextEditingController adres = TextEditingController();
  TextEditingController telefoon = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController merken = TextEditingController();
  TextEditingController opmerking = TextEditingController();

  Soort soort = Soort.tandarts;
  Interesse interesse = Interesse.nietBenaderd;
  List<Contact> partners = [];
  bool bezig = false; // true terwijl we het adres opzoeken
  String foutmelding = '';

  bool get isNieuw => widget.bestaand == null;

  @override
  void initState() {
    super.initState();
    Contact? bestaand = widget.bestaand;
    if (bestaand == null) {
      soort = widget.beginSoort;
      return;
    }
    // Bestaand contact: vul alle velden in.
    soort = bestaand.soort;
    interesse = bestaand.interesse;
    naam.text = bestaand.naam;
    praktijk.text = bestaand.praktijk;
    adres.text = bestaand.adres;
    telefoon.text = bestaand.telefoon;
    email.text = bestaand.email;
    merken.text = bestaand.merken.join(', ');
    opmerking.text = bestaand.opmerking;
    partners = opslag.partnersVan(bestaand);
  }

  String? verplicht(String? waarde) {
    if (waarde == null || waarde.trim() == '') return 'Dit veld is verplicht';
    return null; // null = in orde
  }

  Future<void> opslaan() async {
    if (!formulierSleutel.currentState!.validate()) return;

    setState(() {
      bezig = true;
      foutmelding = '';
    });

    // Adres omzetten naar een plek op de kaart (alleen als het nieuw of veranderd is).
    Contact? bestaand = widget.bestaand;
    LatLng? plaats;
    if (bestaand != null && bestaand.adres == adres.text.trim()) {
      plaats = bestaand.plaats;
    } else {
      plaats = await zoekAdres(adres.text.trim());
    }

    // Na een "await" kan het scherm intussen gesloten zijn; dan stoppen we.
    if (!mounted) return;

    if (plaats == null) {
      setState(() {
        bezig = false;
        foutmelding = 'Adres niet gevonden. Controleer straat, nummer, postcode en gemeente.';
      });
      return;
    }

    // "Straumann, Nobel Biocare" -> ["Straumann", "Nobel Biocare"]
    List<String> merkenLijst = [];
    for (String merk in merken.text.split(',')) {
      if (merk.trim() != '') merkenLijst.add(merk.trim());
    }

    Contact contact;
    if (bestaand == null) {
      contact = Contact(soort: soort, naam: '', adres: '', plaats: plaats, interesse: interesse);
      opslag.voegContactToe(contact);
    } else {
      contact = bestaand;
    }
    contact.soort = soort;
    contact.naam = naam.text.trim();
    contact.praktijk = praktijk.text.trim();
    contact.adres = adres.text.trim();
    contact.plaats = plaats;
    contact.telefoon = telefoon.text.trim();
    contact.email = email.text.trim();
    contact.merken = merkenLijst;
    contact.interesse = interesse;
    contact.opmerking = opmerking.text.trim();

    // Alleen partners van een ander type (een tandarts werkt niet samen met een tandarts).
    List<Contact> geldigePartners = [];
    for (Contact partner in partners) {
      if (partner.soort != soort) geldigePartners.add(partner);
    }
    opslag.zetPartners(contact, geldigePartners);
    opslag.bijgewerkt();

    Navigator.pop(context, contact);
  }

  Future<void> voegPartnerToe() async {
    List<Contact> uitsluiten = List.of(partners);
    if (widget.bestaand != null) uitsluiten.add(widget.bestaand!);

    dynamic gekozen = await toonVenster(context, PartnerKiezer(eigenSoort: soort, uitsluiten: uitsluiten));
    if (gekozen is Contact) {
      setState(() => partners.add(gekozen));
    }
  }

  Future<void> verwijderen() async {
    bool zeker = await vraagBevestiging(
      context,
      'Contact verwijderen?',
      '${widget.bestaand!.naam} en al zijn relaties en bezoeken worden verwijderd.',
    );
    if (!zeker || !mounted) return;
    opslag.verwijderContact(widget.bestaand!);
    opslag.bijgewerkt();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String titel = 'Contact bewerken';
    if (isNieuw) titel = 'Nieuw contact';

    void Function()? opslaanKnop = opslaan;
    if (bezig) opslaanKnop = null; // null = knop uitgeschakeld

    List<Widget> velden = [
      kopje(context, 'Type'),
      SegmentedButton<Soort>(
        segments: [
          for (Soort s in Soort.values)
            ButtonSegment(
              value: s,
              label: Text(soortTekst(s)),
              icon: Vorm(soort: s, kleur: interesseKleur(interesse), grootte: 14),
            ),
        ],
        selected: {soort},
        showSelectedIcon: false,
        onSelectionChanged: (keuze) => setState(() => soort = keuze.first),
      ),
      kopje(context, 'Gegevens'),
      TextFormField(
        controller: naam,
        autofocus: isNieuw,
        decoration: const InputDecoration(labelText: 'Naam *', hintText: 'Dr. An Peeters'),
        validator: verplicht,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: praktijk,
        decoration: const InputDecoration(labelText: 'Praktijk / bedrijfsnaam', hintText: 'Tandartspraktijk De Linde'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: adres,
        decoration: const InputDecoration(
          labelText: 'Adres *',
          hintText: 'Markt 12, 9700 Oudenaarde',
          helperText: 'Wordt automatisch op de kaart gezet',
          prefixIcon: Icon(Icons.place_outlined),
        ),
        validator: verplicht,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: telefoon,
        decoration: const InputDecoration(labelText: 'Telefoon', prefixIcon: Icon(Icons.phone_outlined)),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: email,
        decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: merken,
        decoration: const InputDecoration(
          labelText: 'Huidig implantaatmerk',
          hintText: 'Straumann, Nobel Biocare',
          helperText: 'Meerdere merken scheiden met een komma',
        ),
      ),
      kopje(context, 'Interesse in Bego *'),
      InteresseKiezer(waarde: interesse, onKies: (keuze) => setState(() => interesse = keuze)),
      kopje(context, 'Verbonden met'),
      partnerKeuze(),
      kopje(context, 'Opmerkingen'),
      TextFormField(
        controller: opmerking,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Bv. enkel bereikbaar op dinsdag'),
      ),
    ];

    if (foutmelding != '') {
      velden.add(Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(foutmelding, style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w600)),
      ));
    }

    if (!isNieuw) {
      velden.add(const SizedBox(height: 24));
      velden.add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: verwijderen,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Contact verwijderen'),
        ),
      ));
    }

    return Scaffold(
      appBar: formulierBalk(context, titel, opslaanKnop, bezig: bezig),
      body: Form(
        key: formulierSleutel,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: velden),
      ),
    );
  }

  // De gekozen partners als "chips", plus een knop om er een toe te voegen.
  Widget partnerKeuze() {
    List<Widget> chips = [];
    for (Contact partner in partners) {
      chips.add(InputChip(
        avatar: Vorm(soort: partner.soort, kleur: interesseKleur(partner.interesse), grootte: 14),
        label: Text(partner.naam),
        onDeleted: () => setState(() => partners.remove(partner)),
      ));
    }
    chips.add(ActionChip(
      avatar: const Icon(Icons.add, size: 18),
      label: const Text('Partner toevoegen'),
      onPressed: voegPartnerToe,
    ));
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}
