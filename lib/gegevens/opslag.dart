// Hier zitten alle contacten en relaties.
// Voorlopig enkel in het geheugen: herlaad je de pagina, dan start je opnieuw
// met de testgegevens. Later komt hier de database.

import 'package:flutter/foundation.dart';

import 'contact.dart';
import 'keten.dart';
import 'testgegevens.dart';

// ChangeNotifier = een klasse die schermen kan laten weten "er is iets veranderd".
// Na elke wijziging roep je bijgewerkt() aan; dan tekent het scherm zichzelf opnieuw.
class Opslag extends ChangeNotifier {
  List<Contact> contacten = [];
  List<Relatie> relaties = [];

  Opslag() {
    vulTestgegevens(this);
  }

  void bijgewerkt() {
    notifyListeners();
  }

  // ---------- Contacten ----------

  void voegContactToe(Contact contact) {
    contacten.add(contact);
  }

  void verwijderContact(Contact contact) {
    contacten.remove(contact);
    relaties.removeWhere((relatie) => relatie.bevat(contact));
  }

  // ---------- Relaties ----------

  List<Contact> partnersVan(Contact contact) {
    List<Contact> partners = [];
    for (Relatie relatie in relaties) {
      if (relatie.bevat(contact)) {
        partners.add(relatie.ander(contact));
      }
    }
    return partners;
  }

  Relatie? relatieTussen(Contact a, Contact b) {
    for (Relatie relatie in relaties) {
      if (relatie.bevat(a) && relatie.bevat(b)) {
        return relatie;
      }
    }
    return null;
  }

  // Voegt een relatie toe, of past ze aan als ze al bestaat.
  void voegRelatieToe(Contact a, Contact b, {bool bevestigd = true, String opmerking = ''}) {
    Relatie? bestaand = relatieTussen(a, b);
    if (bestaand != null) {
      bestaand.bevestigd = bevestigd;
      bestaand.opmerking = opmerking;
    } else {
      relaties.add(Relatie(a, b, bevestigd: bevestigd, opmerking: opmerking));
    }
  }

  void verwijderRelatie(Relatie relatie) {
    relaties.remove(relatie);
  }

  // Zorgt dat [contact] precies met deze [partners] verbonden is.
  void zetPartners(Contact contact, List<Contact> partners) {
    List<Relatie> teVerwijderen = [];
    for (Relatie relatie in relaties) {
      if (relatie.bevat(contact) && !partners.contains(relatie.ander(contact))) {
        teVerwijderen.add(relatie);
      }
    }
    for (Relatie relatie in teVerwijderen) {
      relaties.remove(relatie);
    }
    for (Contact partner in partners) {
      if (relatieTussen(contact, partner) == null) {
        relaties.add(Relatie(contact, partner));
      }
    }
  }

  // ---------- Bezoeken ----------

  // Voegt een bezoek toe en past meteen de interesse van het contact aan.
  void voegBezoekToe(Contact contact, Bezoek bezoek) {
    contact.bezoeken.add(bezoek);
    sorteerBezoeken(contact);
    if (contact.laatsteBezoek == bezoek) {
      contact.interesse = bezoek.interesseNa;
    }
  }

  void verwijderBezoek(Contact contact, Bezoek bezoek) {
    contact.bezoeken.remove(bezoek);
  }

  // Nieuwste bezoek vooraan.
  void sorteerBezoeken(Contact contact) {
    contact.bezoeken.sort((a, b) => b.datum.compareTo(a.datum));
  }

  // ---------- Ketens ----------

  // Alle ketens. Elke chirurg is het middelpunt van een keten met:
  // - al zijn partners (tandartsen en eventueel labo's),
  // - de labo's van die tandartsen.
  // Een tandarts zonder chirurg is zelf het middelpunt (met zijn labo's).
  List<Keten> get ketens {
    List<Keten> resultaat = [];
    for (Contact contact in contacten) {
      if (!isKetenMiddelpunt(contact)) continue;

      List<Contact> leden = [contact];
      for (Contact partner in partnersVan(contact)) {
        if (!leden.contains(partner)) leden.add(partner);

        // De labo's van een tandarts horen ook bij de keten.
        if (partner.soort == Soort.tandarts) {
          for (Contact labo in partnersVan(partner)) {
            if (labo.soort == Soort.labo && !leden.contains(labo)) leden.add(labo);
          }
        }
      }

      // Een keten heeft minstens twee contacten.
      if (leden.length >= 2) resultaat.add(Keten(contact, leden));
    }
    return resultaat;
  }

  bool isKetenMiddelpunt(Contact contact) {
    if (contact.soort == Soort.chirurg) return true;
    if (contact.soort == Soort.tandarts) {
      // Alleen als hij met geen enkele chirurg samenwerkt.
      for (Contact partner in partnersVan(contact)) {
        if (partner.soort == Soort.chirurg) return false;
      }
      return true;
    }
    return false;
  }

  List<Keten> ketensVan(Contact contact) {
    List<Keten> resultaat = [];
    for (Keten keten in ketens) {
      if (keten.bevat(contact)) {
        resultaat.add(keten);
      }
    }
    return resultaat;
  }

  // De beste status van alle ketens waar het contact in zit (null = geen keten).
  KetenStatus? besteKetenStatus(Contact contact) {
    KetenStatus? beste;
    for (Keten keten in ketensVan(contact)) {
      if (keten.status == KetenStatus.volledig) return KetenStatus.volledig;
      if (keten.status == KetenStatus.bijna) beste = KetenStatus.bijna;
      if (keten.status == KetenStatus.open && beste == null) beste = KetenStatus.open;
    }
    return beste;
  }
}

// Eén gedeelde opslag voor de hele app.
Opslag opslag = Opslag();
