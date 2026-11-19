// Rekenwerk voor de kaart:
// - contacten die dicht bij elkaar liggen uit elkaar duwen (uitwaaieren);
// - een rechte lijn ombuigen tot een boog, zodat lijnen niet over elkaar liggen.

import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/contact.dart';
import '../models/relatie.dart';

// Geeft voor elk contact de plek waar zijn icoontje getekend wordt.
// Icoontjes die op het scherm minder dan [afstand] pixels van elkaar liggen, worden
// een beetje uit elkaar geduwd. Dat herhalen we tot niets meer overlapt.
// [naarPixels] en [naarPlaats] rekenen tussen een plaats en een punt op het scherm
// (dat hangt af van de zoom, daarom gebeurt dit opnieuw als je in- of uitzoomt).
Map<Contact, LatLng> uitgewaaierdePlekken(
  List<Contact> contacten,
  Offset Function(LatLng plaats) naarPixels,
  LatLng Function(Offset punt) naarPlaats,
  double afstand,
) {
  // Stap 1: waar staat elk icoontje nu op het scherm?
  List<Offset> punten = [];
  for (Contact contact in contacten) {
    punten.add(naarPixels(contact.plaats));
  }

  // Stap 2: twee icoontjes te dicht bij elkaar? Elk een halve stap opzij duwen.
  // Maximaal 50 rondes; meestal is het na een paar rondes al in orde.
  List<bool> verschoven = List.filled(contacten.length, false);
  for (int ronde = 0; ronde < 50; ronde++) {
    bool ietsGeduwd = false;
    for (int i = 0; i < punten.length; i++) {
      for (int j = i + 1; j < punten.length; j++) {
        Offset verschil = punten[j] - punten[i];
        double tussen = verschil.distance;
        if (tussen >= afstand) continue;

        // In welke richting duwen? Liggen ze precies op elkaar (zelfde adres),
        // dan kiezen we zelf een richting, voor elk contact een andere.
        Offset richting;
        if (tussen > 0.01) {
          richting = verschil / tussen;
        } else {
          richting = Offset(cos(j * 2.4), sin(j * 2.4));
        }
        Offset duw = richting * ((afstand - tussen) / 2);
        punten[i] -= duw;
        punten[j] += duw;
        verschoven[i] = true;
        verschoven[j] = true;
        ietsGeduwd = true;
      }
    }
    if (!ietsGeduwd) break;
  }

  // Stap 3: terug omrekenen naar plaatsen op de kaart.
  Map<Contact, LatLng> plekken = {};
  for (int i = 0; i < contacten.length; i++) {
    if (verschoven[i]) {
      plekken[contacten[i]] = naarPlaats(punten[i]);
    } else {
      plekken[contacten[i]] = contacten[i].plaats; // niet verschoven: gewoon op het adres
    }
  }
  return plekken;
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

  // Stap 2: binnen elk groepje de bochten verdelen, bv. bij 3 lijnen: -0.45, 0, 0.45.
  Map<Relatie, double> bochten = {};
  for (List<Relatie> groepje in buren.values) {
    if (groepje.length == 1) {
      bochten[groepje.first] = 0.2; // één lijn: een duidelijke boog
      continue;
    }
    for (int i = 0; i < groepje.length; i++) {
      double bocht = -0.45 + 0.9 * i / (groepje.length - 1);
      Relatie relatie = groepje[i];
      // Alle lijnen in een groepje moeten in dezelfde richting "gelezen" worden,
      // anders buigt een omgekeerde lijn net naar de verkeerde kant.
      if (!inLeesrichting(relatie)) bocht = -bocht;
      bochten[relatie] = bocht;
    }
  }
  return bochten;
}

// Afgeronde plek (ongeveer 5 km), zodat contacten in de buurt van elkaar dezelfde plek krijgen.
String afgerondePlek(LatLng plaats) {
  int breedte = (plaats.latitude * 20).round();
  int lengte = (plaats.longitude * 20).round();
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
