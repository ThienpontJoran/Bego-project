// Een keten = een chirurg met al zijn tandartsen en hun labo's
// (plus de labo's waarmee de chirurg rechtstreeks werkt).
// Een tandarts zonder gekende chirurg krijgt een eigen keten met zijn labo's.
// Een keten kan dus 2, 3 of veel meer contacten bevatten.

import 'package:flutter/material.dart';

import 'contact.dart';

enum KetenStatus { volledig, bijna, open }

class Keten {
  Contact middelpunt; // de chirurg (of tandarts zonder chirurg) waar de keten rond draait
  List<Contact> leden; // alle contacten in de keten, ook het middelpunt
  String naam; // bv. "Keten van Dr. Koen Janssens", of een zelfgekozen naam

  Keten(this.middelpunt, this.leden, this.naam);

  // De leden die nog geen Bego gebruiken.
  List<Contact> get nietMee {
    List<Contact> resultaat = [];
    for (Contact lid in leden) {
      if (lid.interesse != Interesse.gebruiktBego) {
        resultaat.add(lid);
      }
    }
    return resultaat;
  }

  int get aantalMee {
    return leden.length - nietMee.length;
  }

  // Volledig = iedereen gebruikt Bego.
  // Bijna = iedereen op één na: één bezoek kan de keten volledig maken.
  // Open = twee of meer zijn nog niet mee.
  KetenStatus get status {
    int aantalNietMee = nietMee.length;
    if (aantalNietMee == 0) return KetenStatus.volledig;
    if (aantalNietMee == 1) return KetenStatus.bijna;
    return KetenStatus.open;
  }

  bool bevat(Contact contact) {
    return leden.contains(contact);
  }

  // Alle leden van één type, bv. alle labo's in deze keten.
  List<Contact> ledenVan(Soort soort) {
    List<Contact> resultaat = [];
    for (Contact lid in leden) {
      if (lid.soort == soort) resultaat.add(lid);
    }
    return resultaat;
  }
}

String ketenStatusTekst(KetenStatus status) {
  switch (status) {
    case KetenStatus.volledig:
      return 'Volledig Bego';
    case KetenStatus.bijna:
      return 'Bijna';
    case KetenStatus.open:
      return 'Open';
  }
}

Color ketenStatusKleur(KetenStatus status) {
  switch (status) {
    case KetenStatus.volledig:
      return const Color(0xFF2E7D32);
    case KetenStatus.bijna:
      return const Color(0xFFEF6C00);
    case KetenStatus.open:
      return const Color(0xFF78909C);
  }
}
