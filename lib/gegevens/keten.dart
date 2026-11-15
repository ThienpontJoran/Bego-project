// Een keten = een chirurg, een tandarts en een labo die samenwerken.

import 'package:flutter/material.dart';

import 'contact.dart';

enum KetenStatus { volledig, bijna, open }

class Keten {
  Contact chirurg;
  Contact tandarts;
  Contact labo;

  Keten(this.chirurg, this.tandarts, this.labo);

  List<Contact> get leden {
    return [chirurg, tandarts, labo];
  }

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

  KetenStatus get status {
    int aantalMee = 3 - nietMee.length;
    if (aantalMee == 3) return KetenStatus.volledig;
    if (aantalMee == 2) return KetenStatus.bijna;
    return KetenStatus.open;
  }

  bool bevat(Contact contact) {
    return leden.contains(contact);
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
