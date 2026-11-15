// Startpunt van de app: de kaart met alle contacten.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'contact.dart';
import 'detail_paneel.dart';
import 'testgegevens.dart';
import 'vorm.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Bego Netwerkkaart',
    debugShowCheckedModeBanner: false,
    home: KaartPagina(),
  ));
}

// "Stateful" omdat de pagina iets onthoudt dat kan veranderen: welk contact aangeklikt is.
class KaartPagina extends StatefulWidget {
  const KaartPagina({super.key});

  @override
  State<KaartPagina> createState() => _KaartPaginaState();
}

class _KaartPaginaState extends State<KaartPagina> {
  Contact? gekozen; // null = niemand aangeklikt

  // setState zegt tegen Flutter: "er is iets veranderd, teken het scherm opnieuw".
  void kies(Contact? contact) {
    setState(() {
      gekozen = contact;
    });
  }

  // Een contact is "actief" als niemand gekozen is, of als het de gekozene of een partner is.
  bool isActief(Contact contact) {
    if (gekozen == null) return true;
    if (contact == gekozen) return true;
    return zoekPartners(gekozen!, alleRelaties).contains(contact);
  }

  @override
  Widget build(BuildContext context) {
    Widget kaart = Stack(
      children: [
        maakKaart(),
        const Positioned(left: 12, top: 12, child: Legende()),
      ],
    );

    // Geen contact gekozen: alleen de kaart tonen.
    if (gekozen == null) {
      return Scaffold(appBar: maakTitelbalk(), body: kaart);
    }

    Widget paneel = DetailPaneel(
      contact: gekozen!,
      partners: zoekPartners(gekozen!, alleRelaties),
      sluiten: () => kies(null),
      kiesPartner: kies,
    );

    // Breed scherm (laptop): paneel rechts. Smal scherm (gsm): paneel onderaan.
    double breedte = MediaQuery.of(context).size.width;
    if (breedte > 800) {
      return Scaffold(
        appBar: maakTitelbalk(),
        body: Row(children: [
          Expanded(child: kaart),
          SizedBox(width: 360, child: paneel),
        ]),
      );
    } else {
      return Scaffold(
        appBar: maakTitelbalk(),
        body: Column(children: [
          Expanded(child: kaart),
          SizedBox(height: 320, child: paneel),
        ]),
      );
    }
  }

  AppBar maakTitelbalk() {
    return AppBar(title: const Text('Bego Netwerkkaart – testversie'));
  }

  Widget maakKaart() {
    // Een lijn voor elke relatie.
    List<Polyline> lijnen = [];
    for (Relatie relatie in alleRelaties) {
      Color kleur = Colors.black54;
      double dikte = 2;
      if (gekozen != null) {
        if (relatie.bevat(gekozen!)) {
          kleur = Colors.black87;
          dikte = 4;
        } else {
          kleur = Colors.black12;
        }
      }

      StrokePattern stijl = const StrokePattern.solid();
      if (!relatie.bevestigd) {
        stijl = StrokePattern.dashed(segments: [8, 6]); // stippellijn
      }

      lijnen.add(Polyline(
        points: [relatie.eerste.plaats, relatie.tweede.plaats],
        color: kleur,
        strokeWidth: dikte,
        pattern: stijl,
      ));
    }

    // Een icoon voor elk contact.
    List<Marker> iconen = [];
    for (Contact contact in alleContacten) {
      Color kleur = interesseKleur(contact.interesse);
      if (!isActief(contact)) {
        kleur = Colors.grey.shade300;
      }

      iconen.add(Marker(
        point: contact.plaats,
        width: 28,
        height: 28,
        child: GestureDetector(
          onTap: () => kies(contact),
          child: Tooltip(
            message: contact.naam,
            child: Vorm(
              soort: contact.soort,
              kleur: kleur,
              grootte: 24,
              geselecteerd: contact == gekozen,
            ),
          ),
        ),
      ));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(50.95, 3.75), // ongeveer Oost-Vlaanderen
        initialZoom: 9.5,
        onTap: (positie, punt) => kies(null), // klik naast een contact = deselecteren
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'be.bego.netwerkkaart',
        ),
        PolylineLayer(polylines: lijnen),
        MarkerLayer(markers: iconen),
        const RichAttributionWidget(attributions: [
          TextSourceAttribution('OpenStreetMap contributors'),
        ]),
      ],
    );
  }
}

// Het kadertje linksboven dat uitlegt wat de vormen en kleuren betekenen.
class Legende extends StatelessWidget {
  const Legende({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> regels = [];

    for (Soort soort in Soort.values) {
      regels.add(maakRegel(Vorm(soort: soort, kleur: Colors.black54, grootte: 14), soortTekst(soort)));
    }
    regels.add(const Divider());
    for (Interesse interesse in Interesse.values) {
      Widget bolletje = Vorm(soort: Soort.chirurg, kleur: interesseKleur(interesse), grootte: 14);
      regels.add(maakRegel(bolletje, interesseTekst(interesse)));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: regels),
      ),
    );
  }

  Widget maakRegel(Widget icoon, String tekst) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        icoon,
        const SizedBox(width: 8),
        Text(tekst, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
