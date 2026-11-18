// De kaart met alle contacten (vormen) en relaties (lijnen).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/contact.dart';
import '../models/relatie.dart';
import '../models/keten.dart';
import '../services/opslag.dart';
import '../instellingen.dart';
import '../schermen/keten_naam_venster.dart';
import '../schermen/relatie_formulier.dart';
import '../schermen/venster.dart';
import 'kaart_rekenen.dart';
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
    LayerHitNotifier<Relatie> lijnGeraakt = ValueNotifier(null);

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
        // De lagen van onder naar boven:
        children: [
          // 1. Kaart zonder plaatsnamen
          TileLayer(
            urlTemplate: kaartZonderNamen,
            retinaMode: RetinaMode.isHighDensity(context),
            userAgentPackageName: 'be.bego.netwerkkaart',
          ),
          // 2. Lijnen, 3. pootjes en 4. vormen van de contacten.
          //    (Builder: zo weten we de huidige zoom. Die is nodig om contacten die
          //    dicht bij elkaar liggen uit te waaieren, en om namen te tonen als je inzoomt.)
          Builder(builder: (context) {
            MapCamera camera = MapCamera.of(context);
            Map<Contact, LatLng> plekken = uitgewaaierdePlekken(
              contacten,
              camera.projectAtZoom,
              camera.unprojectAtZoom,
              uitwaaierAfstand,
            );
            return Stack(children: [
              // 2. Lijnen tussen partners. Klik op een lijn om ze te bewerken (bv. een kleur geven).
              //    De "lijnGeraakt"-melder vertelt welke lijn(en) onder de muis liggen.
              MouseRegion(
                hitTestBehavior: HitTestBehavior.deferToChild,
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => klikOpLijn(context, lijnGeraakt),
                  child: PolylineLayer<Relatie>(
                    hitNotifier: lijnGeraakt,
                    minimumHitbox: 12, // ook een beetje naast de lijn klikken telt
                    polylines: maakLijnen(uitgelicht, plekken),
                  ),
                ),
              ),
              // 3. Dunne pootjes van een verschoven icoontje naar het echte adres.
              PolylineLayer(polylines: maakPootjes(plekken)),
              // 4. Vormen van de contacten.
              MarkerLayer(markers: maakIconen(camera.zoom, uitgelicht, plekken)),
            ]);
          }),
          // 5. Plaatsnamen bovenop, zodat vormen ze niet bedekken.
          //    IgnorePointer: klikken gaan door deze laag heen naar de vormen eronder.
          IgnorePointer(
            child: TileLayer(
              urlTemplate: kaartAlleenNamen,
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'be.bego.netwerkkaart',
            ),
          ),
          const RichAttributionWidget(attributions: [
            TextSourceAttribution('CARTO'),
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
        child: Align(alignment: Alignment.centerLeft, child: ketenBalk(context, gekozenKeten!)),
      ));
    }

    return Stack(children: lagen);
  }

  // Er is op een lijn geklikt: open het venster om die relatie te bewerken.
  void klikOpLijn(BuildContext context, LayerHitNotifier<Relatie> lijnGeraakt) {
    LayerHitResult<Relatie>? geraakt = lijnGeraakt.value;
    if (geraakt == null || geraakt.hitValues.isEmpty) return;
    Relatie relatie = geraakt.hitValues.first; // bovenste lijn als er meerdere op elkaar liggen
    toonVenster(context, RelatieFormulier(contact: relatie.eerste, bestaand: relatie));
  }

  Widget ketenBalk(BuildContext context, Keten keten) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Label(tekst: ketenStatusTekst(keten.status), kleur: ketenStatusKleur(keten.status)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '${keten.naam} · ${keten.aantalMee}/${keten.leden.length} mee',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Naam wijzigen',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => hernoemKeten(context, keten),
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

  List<Polyline<Relatie>> maakLijnen(List<Contact> uitgelicht, Map<Contact, LatLng> plekken) {
    // Alleen lijnen tussen twee zichtbare contacten.
    List<Relatie> zichtbaar = [];
    for (Relatie relatie in opslag.relaties) {
      if (contacten.contains(relatie.eerste) && contacten.contains(relatie.tweede)) {
        zichtbaar.add(relatie);
      }
    }
    // Elke lijn een eigen bocht, zodat lijnen naast elkaar niet op elkaar liggen.
    Map<Relatie, double> bochten = bochtenVoor(zichtbaar);

    List<Polyline<Relatie>> lijnen = [];
    for (Relatie relatie in zichtbaar) {
      // Standaard grijs; een lijn met een eigen kleur is iets dikker zodat je ze goed ziet.
      Color kleur = const Color(0xFF546E7A).withValues(alpha: 0.7);
      double dikte = 2;
      if (relatie.kleur != null) {
        kleur = relatie.kleur!;
        dikte = 3;
      }

      if (uitgelicht.isNotEmpty) {
        if (lijnUitgelicht(relatie)) {
          if (relatie.kleur == null) kleur = const Color(0xFF263238);
          dikte = dikte + 1.5;
        } else {
          kleur = kleur.withValues(alpha: 0.15);
          dikte = 1.5;
        }
      }

      StrokePattern stijl = const StrokePattern.solid();
      if (!relatie.bevestigd) {
        stijl = StrokePattern.dashed(segments: [8, 6]); // stippellijn
      }

      lijnen.add(Polyline<Relatie>(
        hitValue: relatie, // zo weten we welke relatie je aanklikt
        points: boog(plekken[relatie.eerste]!, plekken[relatie.tweede]!, bochten[relatie]!),
        color: kleur,
        strokeWidth: dikte,
        pattern: stijl,
      ));
    }
    return lijnen;
  }

  // Hoe dicht (in pixels) twee icoontjes mogen liggen voor ze uit elkaar gezet worden.
  static const double uitwaaierAfstand = 26;

  // Een dun grijs lijntje van elk verschoven icoontje naar zijn echte adres.
  List<Polyline> maakPootjes(Map<Contact, LatLng> plekken) {
    List<Polyline> pootjes = [];
    for (Contact contact in contacten) {
      LatLng plek = plekken[contact]!;
      if (plek == contact.plaats) continue; // niet verschoven: geen pootje
      pootjes.add(Polyline(
        points: [contact.plaats, plek],
        color: const Color(0xFF90A4AE),
        strokeWidth: 1,
      ));
    }
    return pootjes;
  }

  List<Marker> maakIconen(double zoom, List<Contact> uitgelicht, Map<Contact, LatLng> plekken) {
    // Grijze contacten eerst tekenen, oplichtende erna (zo liggen die bovenop).
    List<Marker> achteraan = [];
    List<Marker> vooraan = [];
    bool ietsGekozen = uitgelicht.isNotEmpty;
    for (Contact contact in contacten) {
      bool actief = isActief(contact, uitgelicht);
      Marker icoon = maakIcoon(contact, plekken[contact]!, actief, ietsGekozen, zoom);
      if (actief && ietsGekozen) {
        vooraan.add(icoon);
      } else {
        achteraan.add(icoon);
      }
    }
    achteraan.addAll(vooraan);
    return achteraan;
  }

  // [plek] is waar het icoontje staat: het adres, of iets ernaast als het uitgewaaierd is.
  Marker maakIcoon(Contact contact, LatLng plek, bool actief, bool ietsGekozen, double zoom) {
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
    // Zo staat het midden van het icoon precies op de plek.
    return Marker(
      point: plek,
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
