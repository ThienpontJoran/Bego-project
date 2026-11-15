// Adressen opzoeken via OpenStreetMap.
// - zoekSuggesties: suggesties terwijl je typt (dienst "Photon", gemaakt hiervoor).
// - zoekAdres: één adres omzetten naar een plek (dienst "Nominatim"), als reserve.
// Beide zijn gratis en bedoeld voor licht gebruik: prima om te testen.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Eén suggestie in het lijstje onder het adresveld.
class AdresSuggestie {
  String tekst; // bv. "Markt 12, 9700 Oudenaarde"
  String naam; // bv. de naam van een winkel op dat adres (mag leeg zijn)
  LatLng plaats;

  AdresSuggestie(this.tekst, this.naam, this.plaats);
}

Future<List<AdresSuggestie>> zoekSuggesties(String tekst) async {
  List<AdresSuggestie> suggesties = [];
  try {
    Uri url = Uri.https('photon.komoot.io', '/api/', {
      'q': tekst,
      'limit': '10',
      'bbox': '2.5,49.45,6.45,51.55', // rechthoek rond België
      'lat': '51.0', // voorkeur voor Vlaanderen
      'lon': '3.8',
    });
    http.Response antwoord = await http.get(url);
    if (antwoord.statusCode != 200) return suggesties;

    Map<String, dynamic> gegevens = jsonDecode(antwoord.body);
    for (dynamic resultaat in gegevens['features']) {
      Map<String, dynamic> info = resultaat['properties'];
      if (info['countrycode'] != 'BE') continue;

      String adres = maakAdresTekst(info);
      if (adres == '') continue;

      // Geen dubbele suggesties.
      bool alGezien = false;
      for (AdresSuggestie s in suggesties) {
        if (s.tekst == adres) alGezien = true;
      }
      if (alGezien) continue;

      String naam = '';
      if (info['type'] == 'house' && info['name'] != null) naam = info['name'];

      // Let op: Photon geeft eerst de lengtegraad, dan de breedtegraad.
      List coordinaten = resultaat['geometry']['coordinates'];
      LatLng plaats = LatLng(coordinaten[1].toDouble(), coordinaten[0].toDouble());

      suggesties.add(AdresSuggestie(adres, naam, plaats));
    }
  } catch (fout) {
    // Geen internet of iets anders mis: dan gewoon geen suggesties.
  }
  return suggesties;
}

// Maakt van de gegevens van Photon een adres zoals "Markt 12, 9700 Oudenaarde".
String maakAdresTekst(Map<String, dynamic> info) {
  String straat = info['street'] ?? ''; // ?? = "als het null is, neem dan..."
  if (info['type'] == 'street') straat = info['name'] ?? '';
  String nummer = info['housenumber'] ?? '';
  String postcode = info['postcode'] ?? '';
  String gemeente = info['city'] ?? info['name'] ?? '';

  // Tweetalige namen zoals "Ronse - Renaix": we houden het eerste deel.
  straat = straat.split(' - ')[0];
  gemeente = gemeente.split(' - ')[0];

  String eersteDeel = straat;
  if (nummer != '') eersteDeel = '$straat $nummer';

  String tweedeDeel = '$postcode $gemeente'.trim();
  if (tweedeDeel == '') return '';
  if (eersteDeel == '') return tweedeDeel;
  return '$eersteDeel, $tweedeDeel';
}

// Probeert eerst het volledige adres. Lukt dat niet, dan enkel postcode + gemeente
// (het stuk na de laatste komma). Geeft null als niets gevonden werd.
Future<LatLng?> zoekAdres(String adres) async {
  LatLng? plaats = await vraagNominatim(adres);
  if (plaats == null && adres.contains(',')) {
    String gemeente = adres.substring(adres.lastIndexOf(',') + 1);
    plaats = await vraagNominatim(gemeente);
  }
  return plaats;
}

Future<LatLng?> vraagNominatim(String tekst) async {
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
    return null;
  }
}
