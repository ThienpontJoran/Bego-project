// De kaart met alle contacten (vormen) en relaties (lijnen).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../gegevens/contact.dart';
import '../gegevens/keten.dart';
import '../gegevens/opslag.dart';
import 'label.dart';
import 'legende.dart';
import 'vorm.dart';

class Kaart extends StatelessWidget {
  final MapController controller;
  final List<Contact> contacten; // de contacten die getoond worden
  final Contact? gekozen;
  final Keten? gekozenKeten; // een hele keten die oplicht (null = geen)
  final void Function(Contact? contact) onKies;
  final void Function() onSluitKeten;
  final bool legendeOpen;

  const Kaart({
    super.key,
    required this.controller,
    required this.contacten,
    required this.gekozen,
    required this.gekozenKeten,
    required this.onKies,
    required this.onSluitKeten,
    this.legendeOpen = true,
  });

  // Welke contacten lichten op? Leeg = niets gekozen, alles normaal tonen.
  // - een keten gekozen: alle leden van de keten;
  // - een contact gekozen: dat contact en zijn partners.
  List<Contact> uitgelichteContacten() {
    if (gekozenKeten != null) return gekozenKeten!.leden;
    if (gekozen != null) {
      List<Contact> lijst = opslag.partnersVan(gekozen!);
      lijst.add(gekozen!);
      return lijst;
    }
    return [];
  }

  // Welke lijnen lichten op?
  bool lijnUitgelicht(Relatie relatie) {
    if (gekozenKeten != null) {
      return gekozenKeten!.bevat(relatie.eerste) && gekozenKeten!.bevat(relatie.tweede);
    }
    if (gekozen != null) return relatie.bevat(gekozen!);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    List<Contact> uitgelicht = uitgelichteContacten();

    // De lagen liggen op elkaar: eerst de kaart, daarbovenop de knoppen en de legende.
    List<Widget> lagen = [
      FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCameraFit: beginBeeld(),
          initialCenter: const LatLng(50.95, 3.75),
          initialZoom: 9.5,
          minZoom: 7,
          maxZoom: 18,
          onTap: (positie, punt) => onKies(null), // naast een contact klikken = niets gekozen
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'be.bego.netwerkkaart',
          ),
          PolylineLayer(polylines: maakLijnen(uitgelicht)),
          // Builder: zo weten we de huidige zoom, om namen te tonen als je inzoomt.
          Builder(builder: (context) {
            double zoom = MapCamera.of(context).zoom;
            return MarkerLayer(markers: maakIconen(zoom, uitgelicht));
          }),
          const RichAttributionWidget(attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ]),
        ],
      ),
      Positioned(top: 12, right: 12, child: kaartKnoppen()),
      Positioned(left: 12, bottom: 12, child: Legende(beginOpen: legendeOpen)),
    ];

    // Een keten gekozen? Dan een balkje met de naam en een sluitknop.
    if (gekozenKeten != null) {
      lagen.add(Positioned(
        top: 72,
        left: 12,
        right: 72,
        child: Align(alignment: Alignment.centerLeft, child: ketenBalk(gekozenKeten!)),
      ));
    }

    return Stack(children: lagen);
  }

  Widget ketenBalk(Keten keten) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Label(tekst: ketenStatusTekst(keten.status), kleur: ketenStatusKleur(keten.status)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Keten van ${keten.middelpunt.naam} · ${keten.aantalMee}/${keten.leden.length} mee',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(tooltip: 'Sluiten', icon: const Icon(Icons.close, size: 18), onPressed: onSluitKeten),
        ]),
      ),
    );
  }

  // Bij het opstarten: zoom zo dat alle contacten zichtbaar zijn.
  CameraFit? beginBeeld() {
    if (opslag.contacten.isEmpty) return null;
    List<LatLng> punten = [];
    for (Contact contact in opslag.contacten) {
      punten.add(contact.plaats);
    }
    return CameraFit.coordinates(coordinates: punten, padding: const EdgeInsets.all(60), maxZoom: 12);
  }

  void toonAlles() {
    CameraFit? beeld = beginBeeld();
    if (beeld != null) controller.fitCamera(beeld);
  }

  void zoom(double verschil) {
    controller.move(controller.camera.center, controller.camera.zoom + verschil);
  }

  bool isActief(Contact contact, List<Contact> uitgelicht) {
    if (uitgelicht.isEmpty) return true; // niets gekozen: alles actief
    return uitgelicht.contains(contact);
  }

  List<Polyline> maakLijnen(List<Contact> uitgelicht) {
    List<Polyline> lijnen = [];
    for (Relatie relatie in opslag.relaties) {
      // Alleen lijnen tussen twee zichtbare contacten.
      if (!contacten.contains(relatie.eerste) || !contacten.contains(relatie.tweede)) continue;

      Color kleur = const Color(0xFF546E7A).withValues(alpha: 0.7);
      double dikte = 2;
      if (uitgelicht.isNotEmpty) {
        if (lijnUitgelicht(relatie)) {
          kleur = const Color(0xFF263238);
          dikte = 3.5;
        } else {
          kleur = const Color(0xFF546E7A).withValues(alpha: 0.15);
          dikte = 1.5;
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
    return lijnen;
  }

  List<Marker> maakIconen(double zoom, List<Contact> uitgelicht) {
    // Grijze contacten eerst tekenen, oplichtende erna (zo liggen die bovenop).
    List<Marker> achteraan = [];
    List<Marker> vooraan = [];
    bool ietsGekozen = uitgelicht.isNotEmpty;
    for (Contact contact in contacten) {
      bool actief = isActief(contact, uitgelicht);
      Marker icoon = maakIcoon(contact, actief, ietsGekozen, zoom);
      if (actief && ietsGekozen) {
        vooraan.add(icoon);
      } else {
        achteraan.add(icoon);
      }
    }
    achteraan.addAll(vooraan);
    return achteraan;
  }

  Marker maakIcoon(Contact contact, bool actief, bool ietsGekozen, double zoom) {
    Color kleur = interesseKleur(contact.interesse);
    if (!actief) kleur = const Color(0xFFD5DADD);

    // Namen tonen als je ver ingezoomd bent, of voor alles wat oplicht.
    bool toonNaam = zoom >= 11 || (ietsGekozen && actief);

    List<Widget> delen = [
      Vorm(soort: contact.soort, kleur: kleur, grootte: 22, geselecteerd: contact == gekozen),
    ];
    if (toonNaam) {
      delen.add(naamLabel(contact.naam, contact == gekozen));
    }

    // De marker is 70 hoog: 24 leeg + 22 icoon + ruimte voor de naam.
    // Zo staat het midden van het icoon precies op het adres.
    return Marker(
      point: contact.plaats,
      width: 170,
      height: 70,
      child: Column(children: [
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => onKies(contact),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: contact.naam,
              child: Column(mainAxisSize: MainAxisSize.min, children: delen),
            ),
          ),
        ),
      ]),
    );
  }

  Widget naamLabel(String naam, bool vet) {
    FontWeight dikte = FontWeight.w500;
    if (vet) dikte = FontWeight.w800;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        naam,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: dikte, color: const Color(0xFF263238)),
      ),
    );
  }

  Widget kaartKnoppen() {
    return Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IconButton(tooltip: 'Inzoomen', icon: const Icon(Icons.add), onPressed: () => zoom(1)),
        IconButton(tooltip: 'Uitzoomen', icon: const Icon(Icons.remove), onPressed: () => zoom(-1)),
        IconButton(tooltip: 'Toon alles', icon: const Icon(Icons.fit_screen_outlined), onPressed: toonAlles),
      ]),
    );
  }
}
