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
                polylines: maakLijnen(uitgelicht),
              ),
            ),
          ),
          // 3. Vormen van de contacten
          // (Builder: zo weten we de huidige zoom, om namen te tonen en groepjes te maken.)
          Builder(builder: (context) {
            MapCamera camera = MapCamera.of(context);
            return MarkerLayer(markers: maakIconen(context, camera, uitgelicht));
          }),
          // 4. Plaatsnamen bovenop, zodat vormen ze niet bedekken.
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

  List<Polyline<Relatie>> maakLijnen(List<Contact> uitgelicht) {
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
        points: boog(relatie.eerste.plaats, relatie.tweede.plaats, bochten[relatie]!),
        color: kleur,
        strokeWidth: dikte,
        pattern: stijl,
      ));
    }
    return lijnen;
  }

  // Hoe dicht (in pixels) twee icoontjes mogen liggen voor ze samen een groepje worden.
  static const double groepAfstand = 30;

  List<Marker> maakIconen(BuildContext context, MapCamera camera, List<Contact> uitgelicht) {
    double zoom = camera.zoom;
    bool ietsGekozen = uitgelicht.isNotEmpty;

    // Oplichtende contacten (het gekozen contact, zijn partners, een keten) komen nooit
    // in een groepje: die wil je altijd los zien. De rest wordt gegroepeerd.
    List<Contact> losTonen = [];
    List<Contact> teGroeperen = [];
    for (Contact contact in contacten) {
      if (ietsGekozen && isActief(contact, uitgelicht)) {
        losTonen.add(contact);
      } else {
        teGroeperen.add(contact);
      }
    }

    // Grijze/gewone icoontjes eerst tekenen, oplichtende erna (zo liggen die bovenop).
    List<Marker> iconen = [];
    List<List<Contact>> groepjes = groepeer(teGroeperen, camera.projectAtZoom, groepAfstand);
    for (List<Contact> groepje in groepjes) {
      if (groepje.length == 1) {
        iconen.add(maakIcoon(groepje.first, !ietsGekozen, ietsGekozen, zoom));
      } else {
        iconen.add(maakGroepIcoon(context, groepje, ietsGekozen));
      }
    }
    for (Contact contact in losTonen) {
      iconen.add(maakIcoon(contact, true, ietsGekozen, zoom));
    }
    return iconen;
  }

  // Een rond bolletje met het aantal contacten erin.
  Marker maakGroepIcoon(BuildContext context, List<Contact> groepje, bool ietsGekozen) {
    Color kleur = const Color(0xFF37474F);
    if (ietsGekozen) kleur = const Color(0xFFB0BEC5); // grijs als er iets anders gekozen is

    return Marker(
      point: middenVan(groepje),
      width: 34,
      height: 34,
      child: GestureDetector(
        onTap: () => klikOpGroep(context, groepje),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: '${groepje.length} contacten · klik om in te zoomen',
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kleur,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
              ),
              child: Text(
                '${groepje.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Klik op een groepje: inzoomen tot de contacten los van elkaar staan.
  // Liggen ze zo dicht bij elkaar (bv. hetzelfde gebouw) dat inzoomen niet helpt,
  // dan krijg je een lijstje om er een te kiezen.
  void klikOpGroep(BuildContext context, List<Contact> groepje) {
    List<List<Contact>> opMaxZoom = groepeer(
      groepje,
      (plaats) => controller.camera.projectAtZoom(plaats, 18),
      groepAfstand,
    );
    if (opMaxZoom.length == 1) {
      kiesUitLijst(context, groepje);
      return;
    }

    List<LatLng> punten = [];
    for (Contact contact in groepje) {
      punten.add(contact.plaats);
    }
    controller.fitCamera(CameraFit.coordinates(
      coordinates: punten,
      padding: const EdgeInsets.all(80),
      maxZoom: 18,
    ));
  }

  void kiesUitLijst(BuildContext context, List<Contact> groepje) {
    List<Widget> keuzes = [];
    for (Contact contact in groepje) {
      keuzes.add(ListTile(
        leading: Vorm(soort: contact.soort, kleur: interesseKleur(contact.interesse), grootte: 20),
        title: Text(contact.naam),
        onTap: () {
          Navigator.of(context).pop();
          onKies(contact);
        },
      ));
    }
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Welk contact bedoel je?'),
        children: keuzes,
      ),
    );
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
