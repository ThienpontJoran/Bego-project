// Alle gegevens van één contact: kop, contact, Bego, partners, bezoeken, opmerkingen.

import 'package:flutter/material.dart';

import '../models/bezoek.dart';
import '../models/contact.dart';
import '../models/relatie.dart';
import '../utils/hulpfuncties.dart';
import '../utils/kleuren.dart';
import '../models/keten.dart';
import '../services/opslag.dart';
import '../schermen/bezoek_formulier.dart';
import '../schermen/contact_formulier.dart';
import '../schermen/relatie_formulier.dart';
import '../schermen/venster.dart';
import 'label.dart';
import 'vorm.dart';

class DetailPaneel extends StatelessWidget {
  final Contact contact;
  final void Function(Contact partner) onKiesPartner;
  final void Function()? onSluiten; // null = geen sluitknop tonen

  const DetailPaneel({super.key, required this.contact, required this.onKiesPartner, this.onSluiten});

  @override
  Widget build(BuildContext context) {
    List<Contact> partners = opslag.partnersVan(contact);

    List<Widget> delen = [];
    delen.add(kop(context));
    delen.add(const SizedBox(height: 16));
    delen.add(actieknoppen(context));

    delen.add(sectie(context, 'Contactgegevens', contactgegevens()));
    delen.add(sectie(context, 'Bego', begoGegevens()));
    delen.add(sectie(context, 'Partners', partnerRegels(context, partners)));
    delen.add(sectie(context, 'Bezoeken', bezoekRegels(context)));
    Widget opmerking = grijs('Geen opmerkingen');
    if (contact.opmerking != '') opmerking = Text(contact.opmerking);
    delen.add(sectie(context, 'Opmerkingen', [opmerking]));

    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: delen);
  }

  // ---------- Kop ----------

  Widget kop(BuildContext context) {
    String onder = soortTekst(contact.soort);
    if (contact.praktijk != '') onder = '$onder · ${contact.praktijk}';

    List<Widget> labels = [
      Label(tekst: interesseTekst(contact.interesse), kleur: interesseKleur(contact.interesse)),
    ];
    if (contact.langNietBezocht) {
      labels.add(const Label(tekst: 'Lang niet bezocht', kleur: Color(0xFFD32F2F)));
    }

    List<Widget> rij = [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Vorm(soort: contact.soort, kleur: interesseKleur(contact.interesse), grootte: 28),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contact.naam, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(onder, style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    ];
    if (onSluiten != null) {
      rij.add(IconButton(tooltip: 'Sluiten', onPressed: onSluiten, icon: const Icon(Icons.close)));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: rij),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: labels),
    ]);
  }

  Widget actieknoppen(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      FilledButton.icon(
        onPressed: () => toonVenster(context, BezoekFormulier(contact: contact)),
        icon: const Icon(Icons.edit_note),
        label: const Text('Bezoek noteren'),
      ),
      OutlinedButton.icon(
        onPressed: () => toonVenster(context, ContactFormulier(bestaand: contact)),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Bewerken'),
      ),
      OutlinedButton.icon(
        onPressed: () => toonVenster(context, RelatieFormulier(contact: contact)),
        icon: const Icon(Icons.add_link, size: 18),
        label: const Text('Partner'),
      ),
    ]);
  }

  // ---------- Secties ----------

  Widget sectie(BuildContext context, String titel, List<Widget> inhoud) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          titel.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: begoDonkergrijs,
          ),
        ),
        const SizedBox(height: 8),
        ...inhoud, // de drie puntjes zetten alle widgets uit de lijst hier op een rij
      ]),
    );
  }

  List<Widget> contactgegevens() {
    List<Widget> regels = [gegevensRegel(Icons.place_outlined, contact.adres)];
    if (contact.telefoon != '') regels.add(gegevensRegel(Icons.phone_outlined, contact.telefoon));
    if (contact.email != '') regels.add(gegevensRegel(Icons.mail_outline, contact.email));
    return regels;
  }

  List<Widget> begoGegevens() {
    List<Widget> regels = [];

    // Merken
    if (contact.merken.isEmpty) {
      regels.add(gegevensRegel(Icons.category_outlined, 'Geen merk ingevuld'));
    } else {
      regels.add(gegevensRegel(Icons.category_outlined, 'Merk: ${contact.merken.join(', ')}'));
    }

    // Laatste bezoek
    Bezoek? laatste = contact.laatsteBezoek;
    if (laatste == null) {
      regels.add(gegevensRegel(Icons.history, 'Nog nooit bezocht'));
    } else {
      regels.add(gegevensRegel(Icons.history, 'Laatst gesproken: ${geledenTekst(laatste.datum)} (${datumTekst(laatste.datum)})'));
    }

    // Ketens
    for (Keten keten in opslag.ketensVan(contact)) {
      String naam = keten.naam;
      regels.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Label(tekst: ketenStatusTekst(keten.status), kleur: ketenStatusKleur(keten.status)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$naam · ${keten.aantalMee} van ${keten.leden.length} mee',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ]),
      ));
    }
    return regels;
  }

  List<Widget> partnerRegels(BuildContext context, List<Contact> partners) {
    if (partners.isEmpty) {
      return [grijs('Nog geen partners. Voeg er een toe met de knop "Partner".')];
    }

    List<Widget> regels = [];
    // Gegroepeerd per type: eerst chirurgen, dan tandartsen, dan labo's.
    for (Soort soort in Soort.values) {
      List<Contact> vanDitType = [];
      for (Contact partner in partners) {
        if (partner.soort == soort) vanDitType.add(partner);
      }
      if (vanDitType.isEmpty) continue;

      regels.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Text(soortMeervoud(soort), style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ));
      for (Contact partner in vanDitType) {
        Relatie relatie = opslag.relatieTussen(contact, partner)!;
        String onder = interesseTekst(partner.interesse);
        if (!relatie.bevestigd) onder = '$onder · vermoed';
        if (relatie.opmerking != '') onder = '$onder\n${relatie.opmerking}';

        regels.add(ListTile(
          contentPadding: const EdgeInsets.only(left: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Vorm(soort: partner.soort, kleur: interesseKleur(partner.interesse), grootte: 20),
          title: Text(partner.naam, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(onder),
          onTap: () => onKiesPartner(partner),
          trailing: IconButton(
            tooltip: 'Relatie bewerken',
            icon: const Icon(Icons.more_horiz),
            onPressed: () => toonVenster(context, RelatieFormulier(contact: contact, bestaand: relatie)),
          ),
        ));
      }
    }
    return regels;
  }

  List<Widget> bezoekRegels(BuildContext context) {
    if (contact.bezoeken.isEmpty) {
      return [grijs('Nog geen bezoeken genoteerd.')];
    }

    List<Widget> regels = [];
    for (Bezoek bezoek in contact.bezoeken) {
      List<Widget> inhoud = [
        Row(children: [
          Icon(contactmomentIcoon(bezoek.soort), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${contactmomentTekst(bezoek.soort)} · ${datumTekst(bezoek.datum)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Verwijderen',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => verwijderBezoek(context, bezoek),
          ),
        ]),
      ];
      if (bezoek.verslag != '') inhoud.add(Text(bezoek.verslag));
      if (bezoek.volgendeStap != '') {
        String stap = 'Volgende stap: ${bezoek.volgendeStap}';
        if (bezoek.volgendeStapDatum != null) stap = '$stap (${datumTekst(bezoek.volgendeStapDatum!)})';
        inhoud.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.flag_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(stap, style: const TextStyle(fontWeight: FontWeight.w500))),
          ]),
        ));
      }

      regels.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: inhoud),
      ));
    }
    return regels;
  }

  Future<void> verwijderBezoek(BuildContext context, Bezoek bezoek) async {
    bool zeker = await vraagBevestiging(context, 'Bezoek verwijderen?', 'Dit kan je niet ongedaan maken.');
    if (zeker) {
      await opslag.verwijderBezoek(contact, bezoek);
    }
  }

  // ---------- Kleine hulpjes ----------

  Widget gegevensRegel(IconData icoon, String tekst) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icoon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(child: SelectableText(tekst)),
      ]),
    );
  }

  Widget grijs(String tekst) {
    return Text(tekst, style: const TextStyle(color: Colors.grey));
  }
}
