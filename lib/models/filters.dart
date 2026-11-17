// Welke contacten getoond worden: zoekterm, type, kleur, ketenstatus...

import 'contact.dart';
import '../utils/hulpfuncties.dart';
import 'keten.dart';
import '../services/opslag.dart';

class Filters {
  String zoekterm = '';
  Set<Soort> soorten = {}; // leeg = alle types
  Set<Interesse> interesses = {}; // leeg = alle kleuren
  KetenStatus? ketenStatus; // null = maakt niet uit
  bool alleenLangNietBezocht = false;

  // Aantal filters in het filtervenster dat aan staat (voor het bolletje op de knop).
  int get aantalActief {
    int aantal = interesses.length;
    if (ketenStatus != null) aantal++;
    if (alleenLangNietBezocht) aantal++;
    return aantal;
  }

  void wis() {
    interesses = {};
    ketenStatus = null;
    alleenLangNietBezocht = false;
  }

  bool laatZien(Contact contact) {
    if (soorten.isNotEmpty && !soorten.contains(contact.soort)) return false;
    if (interesses.isNotEmpty && !interesses.contains(contact.interesse)) return false;
    if (alleenLangNietBezocht && !contact.langNietBezocht) return false;

    if (ketenStatus != null) {
      bool gevonden = false;
      for (Keten keten in opslag.ketensVan(contact)) {
        if (keten.status == ketenStatus) gevonden = true;
      }
      if (!gevonden) return false;
    }

    // Pas zoeken vanaf 2 letters.
    if (zoekterm.trim().length >= 2 && !pastBijZoekterm(contact, zoekterm)) return false;

    return true;
  }
}
