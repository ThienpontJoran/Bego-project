// Het hoofdscherm.
// Laptop (breed): zijbalk links, kaart in het midden, detailpaneel rechts.
// Gsm (smal): tabbladen onderaan (Kaart, Contacten, Ketens, Opvolging).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/contact.dart';
import '../models/filters.dart';
import '../models/keten.dart';
import '../services/download/download.dart';
import '../services/excel_bestand.dart';
import '../services/inlog_service.dart';
import '../services/opslag.dart';
import '../onderdelen/contactenlijst.dart';
import '../onderdelen/detail_paneel.dart';
import '../onderdelen/kaart.dart';
import '../onderdelen/ketenlijst.dart';
import '../onderdelen/opvolglijst.dart';
import '../onderdelen/vorm.dart';
import 'contact_formulier.dart';
import 'detail_pagina.dart';
import 'filter_venster.dart';
import 'venster.dart';

class Hoofdscherm extends StatefulWidget {
  const Hoofdscherm({super.key});

  @override
  State<Hoofdscherm> createState() => _HoofdschermState();
}

class _HoofdschermState extends State<Hoofdscherm> {
  Contact? gekozen; // het aangeklikte contact (null = niemand)
  Keten? gekozenKeten; // de keten die op de kaart oplicht (null = geen)
  Filters filters = Filters();
  int tabblad = 0; // laptop: 0 = contacten, 1 = ketens, 2 = opvolging
  int mobielTabblad = 0; // gsm: 0 = kaart, 1 = contacten, 2 = ketens, 3 = opvolging
  MapController kaartController = MapController();
  TextEditingController zoekController = TextEditingController();

  @override
  void initState() {
    super.initState();
    opslag.addListener(toonFoutmelding);
    // Net ingelogd: alles ophalen uit de database (in de tests niet).
    if (opslag.bewaarInDatabase) opslag.laadAlles();
  }

  @override
  void dispose() {
    opslag.removeListener(toonFoutmelding);
    super.dispose();
  }

  // Ging er iets mis met de database? Dan tonen we onderaan een melding.
  void toonFoutmelding() {
    String? melding = opslag.foutmelding;
    if (melding == null) return;
    opslag.foutmelding = null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(melding)));
  }

  Future<void> uitloggen() async {
    bool zeker = await vraagBevestiging(context, 'Uitloggen?', 'Je moet daarna opnieuw inloggen.');
    if (!zeker) return;
    await inlogService.logUit();
    opslag.leegMaken();
  }

  Widget uitlogKnop() {
    return IconButton(tooltip: 'Uitloggen', onPressed: uitloggen, icon: const Icon(Icons.logout));
  }

  // Alle contacten en relaties downloaden als Excel-bestand, bv. "bego_netwerkkaart_2026-11-20.xlsx".
  void downloadExcel() {
    DateTime nu = DateTime.now();
    String maand = nu.month.toString().padLeft(2, '0');
    String dag = nu.day.toString().padLeft(2, '0');
    List<int> inhoud = maakExcel(opslag.contacten, opslag.relaties);
    downloadBestand(inhoud, 'bego_netwerkkaart_${nu.year}-$maand-$dag.xlsx');
  }

  Widget excelKnop() {
    return IconButton(tooltip: 'Download als Excel', onPressed: downloadExcel, icon: const Icon(Icons.download));
  }

  bool isBreed() {
    return MediaQuery.of(context).size.width >= 900;
  }

  // ---------- Acties ----------

  // Toon een hele keten op de kaart: alle leden lichten op en we zoomen erop in.
  void toonKeten(Keten keten) {
    setState(() {
      gekozenKeten = keten;
      gekozen = null;
      mobielTabblad = 0; // op de gsm: naar het tabblad Kaart
    });
    List<LatLng> punten = [];
    for (Contact lid in keten.leden) {
      punten.add(lid.plaats);
    }
    kaartController.fitCamera(
      CameraFit.coordinates(coordinates: punten, padding: const EdgeInsets.all(90), maxZoom: 12),
    );
  }

  // Na een wijziging (bv. een bezoek) worden de ketens opnieuw berekend.
  // Zoek dan de nieuwe versie van de gekozen keten (zelfde middelpunt).
  Keten? vernieuwdeKeten() {
    if (gekozenKeten == null) return null;
    for (Keten keten in opslag.ketens) {
      if (keten.middelpunt == gekozenKeten!.middelpunt) return keten;
    }
    return null;
  }

  // Klik op een contact op de kaart (of naast een contact: null).
  void kiesOpKaart(Contact? contact) {
    setState(() {
      gekozen = contact;
      gekozenKeten = null;
    });
    if (contact != null && !isBreed()) openDetailPagina(contact);
  }

  // Klik op een contact in een lijst: kies het en zoom ernaartoe.
  void kiesUitLijst(Contact contact) {
    setState(() {
      gekozen = contact;
      gekozenKeten = null;
    });
    if (isBreed()) {
      zoomNaar(contact);
    } else {
      openDetailPagina(contact);
    }
  }

  void zoomNaar(Contact contact) {
    double zoom = kaartController.camera.zoom;
    if (zoom < 11) zoom = 11;
    kaartController.move(contact.plaats, zoom);
  }

  Future<void> openDetailPagina(Contact contact) async {
    dynamic resultaat = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DetailPagina(contact: contact)),
    );
    // De pagina geeft een contact terug als je op "Op kaart" klikt.
    if (resultaat is Contact) {
      setState(() {
        gekozen = resultaat;
        mobielTabblad = 0;
      });
      zoomNaar(resultaat);
    }
  }

  Future<void> nieuwContact() async {
    dynamic nieuw = await toonVenster(context, const ContactFormulier());
    if (nieuw is Contact) kiesUitLijst(nieuw);
  }

  Future<void> openFilters() async {
    await toonVenster(context, FilterVenster(filters: filters));
    setState(() {}); // filters kunnen veranderd zijn: scherm opnieuw tekenen
  }

  void zoekVeranderd(String tekst) {
    setState(() {
      filters.zoekterm = tekst;
      tabblad = 0; // toon de zoekresultaten
    });
  }

  // ---------- Welke contacten tonen we? ----------

  List<Contact> gefilterdeContacten() {
    List<Contact> resultaat = [];
    for (Contact contact in opslag.contacten) {
      if (filters.laatZien(contact)) resultaat.add(contact);
    }
    return resultaat;
  }

  // Op de kaart tonen we ook altijd het gekozen contact en zijn partners,
  // en alle leden van de gekozen keten (ook als de filters ze zouden verbergen).
  List<Contact> kaartContacten() {
    List<Contact> resultaat = gefilterdeContacten();
    List<Contact> extra = [];
    Contact? g = gekozen;
    if (g != null) {
      extra.add(g);
      extra.addAll(opslag.partnersVan(g));
    }
    if (gekozenKeten != null) {
      extra.addAll(gekozenKeten!.leden);
    }
    for (Contact contact in extra) {
      if (!resultaat.contains(contact)) resultaat.add(contact);
    }
    return resultaat;
  }

  // ---------- Opbouw van het scherm ----------

  @override
  Widget build(BuildContext context) {
    // Teken opnieuw zodra er iets in de opslag verandert (contact toegevoegd, bezoek...).
    return ListenableBuilder(
      listenable: opslag,
      builder: (context, child) {
        // Is het gekozen contact intussen verwijderd? Dan is er niets meer gekozen.
        if (gekozen != null && !opslag.contacten.contains(gekozen)) gekozen = null;
        gekozenKeten = vernieuwdeKeten();

        // De eerste keer laden: een draaiend wieltje.
        if (opslag.aanHetLaden && opslag.contacten.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (isBreed()) return breedScherm();
        return smalScherm();
      },
    );
  }

  Widget breedScherm() {
    List<Widget> kolommen = [
      SizedBox(width: 380, child: zijbalk()),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
          child: Card(clipBehavior: Clip.antiAlias, child: kaart(true)),
        ),
      ),
    ];

    if (gekozen != null) {
      kolommen.add(SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: DetailPaneel(
              contact: gekozen!,
              onKiesPartner: kiesUitLijst,
              onSluiten: () => kiesOpKaart(null),
            ),
          ),
        ),
      ));
    }

    return Scaffold(body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: kolommen));
  }

  Widget smalScherm() {
    Widget kaartTab = Stack(children: [
      kaart(false),
      Positioned(top: 12, left: 12, right: 76, child: zoekKnopMobiel()),
    ]);

    Widget contactenTab = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
        child: Row(children: [
          logo(),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${opslag.contacten.length} contacten', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          excelKnop(),
          uitlogKnop(),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: zoekveld()),
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: soortKnoppen()),
      Expanded(child: lijstVoorTabblad(0)),
    ]);

    return Scaffold(
      body: SafeArea(
        // IndexedStack: alle tabbladen blijven bestaan, maar je ziet er maar één.
        child: IndexedStack(index: mobielTabblad, children: [
          kaartTab,
          contactenTab,
          lijstVoorTabblad(1),
          lijstVoorTabblad(2),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: nieuwContact,
        icon: const Icon(Icons.add),
        label: const Text('Nieuw contact'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobielTabblad,
        onDestinationSelected: (nummer) => setState(() => mobielTabblad = nummer),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Kaart'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Contacten'),
          NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: 'Ketens'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Opvolging'),
        ],
      ),
    );
  }

  Widget kaart(bool legendeOpen) {
    return Kaart(
      controller: kaartController,
      contacten: kaartContacten(),
      gekozen: gekozen,
      gekozenKeten: gekozenKeten,
      onKies: kiesOpKaart,
      onSluitKeten: () => setState(() => gekozenKeten = null),
      legendeOpen: legendeOpen,
    );
  }

  Widget zijbalk() {
    // Aantal ketens voor op het tabblad.
    int aantalKetens = opslag.ketens.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo met de tekst "BEGO" erbij.
              Image.asset('images/logo_met_tekst.png', height: 30),
              const SizedBox(height: 2),
              Text('Netwerkkaart · ${opslag.contacten.length} contacten',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          FilledButton.icon(onPressed: nieuwContact, icon: const Icon(Icons.add), label: const Text('Nieuw')),
          excelKnop(),
          uitlogKnop(),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: zoekveld()),
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 12), child: soortKnoppen()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            const ButtonSegment(value: 0, label: Text('Contacten')),
            ButtonSegment(value: 1, label: Text('Ketens ($aantalKetens)')),
            const ButtonSegment(value: 2, label: Text('Opvolging')),
          ],
          selected: {tabblad},
          onSelectionChanged: (keuze) => setState(() => tabblad = keuze.first),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: lijstVoorTabblad(tabblad)),
    ]);
  }

  Widget lijstVoorTabblad(int nummer) {
    if (nummer == 1) return KetenLijst(onKies: kiesUitLijst, onToonKeten: toonKeten);
    if (nummer == 2) return OpvolgLijst(onKies: kiesUitLijst);
    return ContactenLijst(contacten: gefilterdeContacten(), gekozen: gekozen, onKies: kiesUitLijst);
  }

  // Het logo van Bego (zonder tekst). De afbeeldingen staan in de map "images".
  Widget logo() {
    return Image.asset('images/logo.jpg', width: 36, height: 36);
  }

  Widget zoekveld() {
    Widget? wisKnop;
    if (filters.zoekterm != '') {
      wisKnop = IconButton(
        tooltip: 'Wissen',
        icon: const Icon(Icons.clear),
        onPressed: () {
          zoekController.clear();
          zoekVeranderd('');
        },
      );
    }

    return Row(children: [
      Expanded(
        child: TextField(
          controller: zoekController,
          onChanged: zoekVeranderd,
          decoration: InputDecoration(
            hintText: 'Zoek naam, gemeente, merk...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: wisKnop,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Badge(
        isLabelVisible: filters.aantalActief > 0,
        label: Text('${filters.aantalActief}'),
        child: IconButton.filledTonal(
          tooltip: 'Filters',
          onPressed: openFilters,
          icon: const Icon(Icons.tune),
        ),
      ),
    ]);
  }

  // Drie knoppen: alleen chirurgen, tandartsen of labo's tonen.
  Widget soortKnoppen() {
    List<Widget> knoppen = [];
    for (Soort soort in Soort.values) {
      knoppen.add(FilterChip(
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        avatar: Vorm(soort: soort, kleur: Colors.blueGrey, grootte: 13),
        label: Text(soortMeervoud(soort)),
        selected: filters.soorten.contains(soort),
        onSelected: (aan) {
          setState(() {
            if (aan) {
              filters.soorten.add(soort);
            } else {
              filters.soorten.remove(soort);
            }
          });
        },
      ));
    }
    return Wrap(spacing: 6, runSpacing: 6, children: knoppen);
  }

  // Op de gsm: een zoekbalk op de kaart die naar het tabblad Contacten springt.
  Widget zoekKnopMobiel() {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => setState(() => mobielTabblad = 1),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(Icons.search),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Zoek een contact...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
