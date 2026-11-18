// Rekenwerk voor de kaart:
// - contacten die dicht bij elkaar liggen samen nemen in een groepje (bolletje met een getal);
// - een rechte lijn ombuigen tot een boog, zodat lijnen niet over elkaar liggen.

import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/contact.dart';
import '../models/relatie.dart';

// Zet de contacten in groepjes. Twee contacten komen in hetzelfde groepje als ze
// op het scherm minder dan [afstand] pixels van elkaar liggen.
// [naarPixels] rekent een plaats om naar een punt op het scherm (hangt af van de zoom).
List<List<Contact>> groepeer(List<Contact> contacten, Offset Function(LatLng plaats) naarPixels, double afstand) {
  List<List<Contact>> groepjes = [];
  List<Offset> middens = []; // het punt waar elk groepje begon

  for (Contact contact in contacten) {
    Offset punt = naarPixels(contact.plaats);
    bool geplaatst = false;
    for (int i = 0; i < groepjes.length; i++) {
      if ((punt - middens[i]).distance < afstand) {
        groepjes[i].add(contact);
        geplaatst = true;
        break;
      }
    }
    if (!geplaatst) {
      groepjes.add([contact]);
      middens.add(punt);
    }
  }
  return groepjes;
}

// Het midden van een groepje contacten.
LatLng middenVan(List<Contact> groepje) {
  double breedte = 0;
  double lengte = 0;
  for (Contact contact in groepje) {
    breedte += contact.plaats.latitude;
    lengte += contact.plaats.longitude;
  }
  return LatLng(breedte / groepje.length, lengte / groepje.length);
}

// Maakt van een rechte lijn een boog.
// [bocht] zegt hoe ver de boog uitwijkt, als deel van de lengte van de lijn:
// 0 = recht, 0.2 = het midden wijkt 20% van de lengte opzij. Negatief = naar de andere kant.
List<LatLng> boog(LatLng van, LatLng naar, double bocht) {
  // We rekenen in "kaartpixels" zodat de boog er overal op de kaart even rond uitziet.
  const Crs kaart = Epsg3857();
  const double zoom = 10;
  Offset a = kaart.latLngToOffset(van, zoom);
  Offset b = kaart.latLngToOffset(naar, zoom);

  Offset verschil = b - a;
  Offset loodrecht = Offset(-verschil.dy, verschil.dx); // een kwartslag gedraaid
  Offset trekpunt = (a + b) / 2 + loodrecht * bocht; // hier "trekt" de boog naartoe

  // Een boog met 20 stukjes (kwadratische Bézier-kromme).
  List<LatLng> punten = [];
  const int stukjes = 20;
  for (int i = 0; i <= stukjes; i++) {
    double t = i / stukjes;
    double u = 1 - t;
    Offset punt = a * (u * u) + trekpunt * (2 * u * t) + b * (t * t);
    punten.add(kaart.offsetToLatLng(punt, zoom));
  }
  return punten;
}

// Geeft elke relatie een eigen bocht. Lijnen die ongeveer tussen dezelfde twee plekken lopen
// krijgen elk een andere bocht, zodat ze uit elkaar waaieren in plaats van op elkaar te liggen.
Map<Relatie, double> bochtenVoor(List<Relatie> relaties) {
  // Stap 1: lijnen met (ongeveer) dezelfde begin- en eindplek samen zetten.
  Map<String, List<Relatie>> buren = {};
  for (Relatie relatie in relaties) {
    String sleutel = plekSleutel(relatie);
    buren.putIfAbsent(sleutel, () => []);
    buren[sleutel]!.add(relatie);
  }

  // Stap 2: binnen elk groepje de bochten verdelen, bv. bij 3 lijnen: -0.25, 0, 0.25.
  Map<Relatie, double> bochten = {};
  for (List<Relatie> groepje in buren.values) {
    if (groepje.length == 1) {
      bochten[groepje.first] = 0.12; // één lijn: een lichte boog
      continue;
    }
    for (int i = 0; i < groepje.length; i++) {
      double bocht = -0.25 + 0.5 * i / (groepje.length - 1);
      Relatie relatie = groepje[i];
      // Alle lijnen in een groepje moeten in dezelfde richting "gelezen" worden,
      // anders buigt een omgekeerde lijn net naar de verkeerde kant.
      if (!inLeesrichting(relatie)) bocht = -bocht;
      bochten[relatie] = bocht;
    }
  }
  return bochten;
}

// Afgeronde plek (ongeveer 2 km), zodat contacten vlak bij elkaar dezelfde plek krijgen.
String afgerondePlek(LatLng plaats) {
  int breedte = (plaats.latitude * 50).round();
  int lengte = (plaats.longitude * 50).round();
  return '$breedte,$lengte';
}

// Dezelfde sleutel voor A→B en B→A.
String plekSleutel(Relatie relatie) {
  String a = afgerondePlek(relatie.eerste.plaats);
  String b = afgerondePlek(relatie.tweede.plaats);
  if (a.compareTo(b) <= 0) return '$a|$b';
  return '$b|$a';
}

// Loopt de lijn van de "kleinste" plek naar de "grootste"?
bool inLeesrichting(Relatie relatie) {
  String a = afgerondePlek(relatie.eerste.plaats);
  String b = afgerondePlek(relatie.tweede.plaats);
  return a.compareTo(b) <= 0;
}
