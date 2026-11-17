// Kleine hulpfuncties voor datums, teksten en zoeken.

import '../models/contact.dart';

// Vandaag om middernacht (zonder uur).
DateTime vandaag() {
  DateTime nu = DateTime.now();
  return DateTime(nu.year, nu.month, nu.day);
}

// 2026-11-05 -> "05/11/2026"
String datumTekst(DateTime datum) {
  String dag = datum.day.toString().padLeft(2, '0');
  String maand = datum.month.toString().padLeft(2, '0');
  return '$dag/$maand/${datum.year}';
}

// Bv. "vandaag", "3 dagen geleden", "2 maanden geleden"
String geledenTekst(DateTime datum) {
  int dagen = vandaag().difference(DateTime(datum.year, datum.month, datum.day)).inDays;
  if (dagen <= 0) return 'vandaag';
  if (dagen == 1) return 'gisteren';
  if (dagen < 14) return '$dagen dagen geleden';
  if (dagen < 60) return '${dagen ~/ 7} weken geleden'; // ~/ = delen zonder komma
  if (dagen < 365) return '${dagen ~/ 30} maanden geleden';
  return 'meer dan een jaar geleden';
}

// "Markt 12, 9700 Oudenaarde" -> "Oudenaarde"
String gemeenteVan(String adres) {
  String deel = adres;
  int komma = adres.lastIndexOf(',');
  if (komma != -1) {
    deel = adres.substring(komma + 1);
  }
  List<String> woorden = deel.trim().split(' ');
  // Eerste woord is een postcode? Dan laten we het weg.
  if (woorden.length > 1 && int.tryParse(woorden[0]) != null) {
    woorden.removeAt(0);
  }
  return woorden.join(' ');
}

// Maakt tekst klaar om te zoeken: kleine letters, geen accenten
// en geen dubbele letters. Zo vindt "peters" ook "Peeters".
String maakZoekbaar(String tekst) {
  Map<String, String> accenten = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  String klein = tekst.toLowerCase();
  String resultaat = '';
  String vorige = '';
  for (int i = 0; i < klein.length; i++) {
    String letter = klein[i];
    if (accenten.containsKey(letter)) {
      letter = accenten[letter]!;
    }
    if (letter != vorige) {
      resultaat = resultaat + letter;
    }
    vorige = letter;
  }
  return resultaat;
}

// Zoekt in naam, praktijk, adres (dus ook gemeente), merken en opmerkingen.
bool pastBijZoekterm(Contact contact, String zoekterm) {
  String alles = '${contact.naam} ${contact.praktijk} ${contact.adres} '
      '${contact.merken.join(' ')} ${contact.opmerking}';
  return maakZoekbaar(alles).contains(maakZoekbaar(zoekterm.trim()));
}
