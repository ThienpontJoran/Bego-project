// Zet een adres om naar een plek op de kaart via OpenStreetMap (Nominatim).
// Gratis, maar bedoeld voor licht gebruik: prima om te testen.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Probeert eerst het volledige adres. Lukt dat niet, dan enkel postcode + gemeente
// (het stuk na de laatste komma). Geeft null als niets gevonden werd.
Future<LatLng?> zoekAdres(String adres) async {
  LatLng? plaats = await vraagOpenStreetMap(adres);
  if (plaats == null && adres.contains(',')) {
    String gemeente = adres.substring(adres.lastIndexOf(',') + 1);
    plaats = await vraagOpenStreetMap(gemeente);
  }
  return plaats;
}

Future<LatLng?> vraagOpenStreetMap(String tekst) async {
  try {
    Uri url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': tekst,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'be',
    });
    http.Response antwoord = await http.get(url);
    if (antwoord.statusCode != 200) return null;

    List resultaten = jsonDecode(antwoord.body);
    if (resultaten.isEmpty) return null;

    double breedte = double.parse(resultaten[0]['lat']);
    double lengte = double.parse(resultaten[0]['lon']);
    return LatLng(breedte, lengte);
  } catch (fout) {
    return null; // geen internet of iets anders mis
  }
}
