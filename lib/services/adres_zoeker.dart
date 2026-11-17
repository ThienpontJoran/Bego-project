// Adressen opzoeken. We gebruiken drie gratis diensten:
// 1. Vlaamse overheid (Digitaal Vlaanderen): officieel adressenregister, heel nauwkeurig,
//    maar alleen Vlaanderen. Dit proberen we altijd eerst.
// 2. Photon (OpenStreetMap): suggesties voor adressen buiten Vlaanderen.
// 3. Nominatim (OpenStreetMap): laatste redmiddel bij het opslaan.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Eén suggestie in het lijstje onder het adresveld.
class AdresSuggestie {
  String tekst; // bv. "Markt 12, 9700 Oudenaarde"
  String naam; // bv. de naam van een winkel op dat adres (mag leeg zijn)
  LatLng? plaats; // null = plek nog niet gekend (wordt opgezocht als je erop klikt)

  AdresSuggestie(this.tekst, this.naam, this.plaats);
}

// Suggesties terwijl je typt: eerst Vlaanderen, en als dat niets geeft, Photon.
Future<List<AdresSuggestie>> zoekSuggesties(String tekst) async {
  List<AdresSuggestie> suggesties = await suggestiesVlaanderen(tekst);
  if (suggesties.isEmpty) {
    suggesties = await suggestiesPhoton(tekst);
  }
  return suggesties;
}

// ---------- Vlaamse overheid ----------

// Geeft alleen teksten terug (zonder plek). De plek vragen we pas op als je klikt.
Future<List<AdresSuggestie>> suggestiesVlaanderen(String tekst) async {
  List<AdresSuggestie> suggesties = [];
  try {
    Uri url = Uri.https('geo.api.vlaanderen.be', '/geolocation/v4/Suggestion', {'q': tekst, 'c': '8'});
    http.Response antwoord = await http.get(url);
    if (antwoord.statusCode != 200) return suggesties;

    Map<String, dynamic> gegevens = jsonDecode(antwoord.body);
    for (dynamic adres in gegevens['SuggestionResult']) {
      suggesties.add(AdresSuggestie(adres, '', null));
    }
  } catch (fout) {
    // Geen internet of iets anders mis: dan gewoon geen suggesties.
  }
  return suggesties;
}

// Zoekt de exacte plek van een adres in het Vlaamse adressenregister.
Future<LatLng?> plekVlaanderen(String adres) async {
  try {
    Uri url = Uri.https('geo.api.vlaanderen.be', '/geolocation/v4/Location', {'q': adres, 'c': '1'});
    http.Response antwoord = await http.get(url);
    if (antwoord.statusCode != 200) return null;

    Map<String, dynamic> gegevens = jsonDecode(antwoord.body);
    List resultaten = gegevens['LocationResult'];
    if (resultaten.isEmpty) return null;

    Map<String, dynamic> plek = resultaten[0]['Location'];
    return LatLng(plek['Lat_WGS84'].toDouble(), plek['Lon_WGS84'].toDouble());
  } catch (fout) {
    return null;
  }
}

// ---------- Photon (buiten Vlaanderen) ----------

Future<List<AdresSuggestie>> suggestiesPhoton(String tekst) async {
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

// ---------- Eén adres omzetten naar een plek ----------

// Probeert eerst Vlaanderen, dan Nominatim met het volledige adres,
// en tot slot enkel postcode + gemeente (het stuk na de laatste komma).
// Geeft null als niets gevonden werd.
Future<LatLng?> zoekAdres(String adres) async {
  LatLng? plaats = await plekVlaanderen(adres);
  if (plaats != null) return plaats;

  plaats = await vraagNominatim(adres);
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
