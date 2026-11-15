// Formulier om een bezoek (of telefoon, e-mail, beurs) te noteren.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/hulpfuncties.dart';
import '../gegevens/opslag.dart';
import '../onderdelen/interesse_kiezer.dart';
import '../onderdelen/kopje.dart';
import 'venster.dart';

class BezoekFormulier extends StatefulWidget {
  final Contact contact;

  const BezoekFormulier({super.key, required this.contact});

  @override
  State<BezoekFormulier> createState() => _BezoekFormulierState();
}

class _BezoekFormulierState extends State<BezoekFormulier> {
  DateTime datum = vandaag();
  Contactmoment soort = Contactmoment.bezoek;
  TextEditingController verslag = TextEditingController();
  TextEditingController volgendeStap = TextEditingController();
  DateTime? stapDatum;
  Interesse interesse = Interesse.nietBenaderd;

  @override
  void initState() {
    super.initState();
    interesse = widget.contact.interesse; // standaard: blijft hetzelfde
  }

  Future<DateTime?> kiesDatum(DateTime begin) {
    return showDatePicker(
      context: context,
      initialDate: begin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }

  void opslaan() {
    Bezoek bezoek = Bezoek(
      datum: datum,
      soort: soort,
      verslag: verslag.text.trim(),
      volgendeStap: volgendeStap.text.trim(),
      volgendeStapDatum: stapDatum,
      interesseNa: interesse,
    );
    opslag.voegBezoekToe(widget.contact, bezoek);
    opslag.bijgewerkt();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Knopjes voor het soort contact.
    List<Widget> soortKnoppen = [];
    for (Contactmoment moment in Contactmoment.values) {
      soortKnoppen.add(ChoiceChip(
        showCheckmark: false,
        avatar: Icon(contactmomentIcoon(moment), size: 18),
        label: Text(contactmomentTekst(moment)),
        selected: moment == soort,
        onSelected: (aan) => setState(() => soort = moment),
      ));
    }

    // Knop voor de datum van de volgende stap.
    String stapDatumTekst = 'Datum kiezen';
    if (stapDatum != null) stapDatumTekst = datumTekst(stapDatum!);
    List<Widget> stapDatumKnoppen = [
      OutlinedButton.icon(
        icon: const Icon(Icons.event, size: 18),
        label: Text(stapDatumTekst),
        onPressed: () async {
          DateTime? gekozen = await kiesDatum(stapDatum ?? vandaag().add(const Duration(days: 7)));
          if (gekozen != null) setState(() => stapDatum = gekozen);
        },
      ),
    ];
    if (stapDatum != null) {
      stapDatumKnoppen.add(IconButton(
        tooltip: 'Datum wissen',
        icon: const Icon(Icons.clear),
        onPressed: () => setState(() => stapDatum = null),
      ));
    }

    List<Widget> velden = [
      kopje(context, 'Wanneer'),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(datumTekst(datum)),
          onPressed: () async {
            DateTime? gekozen = await kiesDatum(datum);
            if (gekozen != null) setState(() => datum = gekozen);
          },
        ),
      ),
      kopje(context, 'Soort contact'),
      Wrap(spacing: 8, runSpacing: 8, children: soortKnoppen),
      kopje(context, 'Verslag'),
      TextField(
        controller: verslag,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(hintText: 'Wat is er besproken?'),
      ),
      kopje(context, 'Volgende stap (optioneel)'),
      TextField(
        controller: volgendeStap,
        decoration: const InputDecoration(hintText: 'Bv. demo inplannen', prefixIcon: Icon(Icons.flag_outlined)),
      ),
      const SizedBox(height: 8),
      Row(children: stapDatumKnoppen),
      kopje(context, 'Interesse na dit contact'),
      InteresseKiezer(waarde: interesse, onKies: (keuze) => setState(() => interesse = keuze)),
    ];

    return Scaffold(
      appBar: formulierBalk(context, 'Bezoek noteren · ${widget.contact.naam}', opslaan),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: velden),
    );
  }
}
