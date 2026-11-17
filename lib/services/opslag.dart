// Hier zitten alle contacten en relaties van de app.
// Bij het inloggen halen we alles op uit Supabase (laadAlles).
// Pas je iets aan, dan:
//   1. veranderen we het meteen in het geheugen (zo voelt de app snel aan),
//   2. bewaren we het daarna in de database via de repositories.

import 'package:flutter/material.dart';

import '../models/bezoek.dart';
import '../models/contact.dart';
import '../models/keten.dart';
import '../models/relatie.dart';
import '../repositories/bezoek_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/relatie_repository.dart';

// ChangeNotifier = een klasse die schermen kan laten weten "er is iets veranderd".
// Na elke wijziging roepen we notifyListeners() aan; dan tekent het scherm zichzelf opnieuw.
class Opslag extends ChangeNotifier {
  List<Contact> contacten = [];
  List<Relatie> relaties = [];

  bool bewaarInDatabase = true; // false in de tests: dan blijft alles in het geheugen
  bool aanHetLaden = false;
  String? foutmelding; // wordt onderaan het scherm getoond (null = geen fout)

  ContactRepository contactRepository = ContactRepository();
  BezoekRepository bezoekRepository = BezoekRepository();
  RelatieRepository relatieRepository = RelatieRepository();

  // ---------- Database ----------

  // Haalt alle contacten, bezoeken en relaties op uit de database.
  Future<void> laadAlles() async {
    aanHetLaden = true;
    notifyListeners();
    try {
      List<Contact> nieuweContacten = await contactRepository.haalAlleOp();

      // Een "map" om snel een contact te vinden op zijn id.
      Map<String, Contact> contactVanId = {};
      for (Contact contact in nieuweContacten) {
        contactVanId[contact.id] = contact;
      }

      await bezoekRepository.haalAlleOp(contactVanId);
      for (Contact contact in nieuweContacten) {
        sorteerBezoeken(contact);
      }
      List<Relatie> nieuweRelaties = await relatieRepository.haalAlleOp(contactVanId);

      contacten = nieuweContacten;
      relaties = nieuweRelaties;
    } catch (fout) {
      debugPrint('Laden mislukt: $fout');
      foutmelding = 'De gegevens konden niet geladen worden. Controleer je internet.';
    }
    aanHetLaden = false;
    notifyListeners();
  }

  // Bij het uitloggen: niets van de vorige gebruiker in het geheugen laten staan.
  void leegMaken() {
    contacten = [];
    relaties = [];
    notifyListeners();
  }

  // Voert een taak uit op de database (niet in de tests).
  // Lukt het niet (bv. geen internet), dan tonen we een melding en halen we alles
  // opnieuw op, zodat je ziet wat er echt bewaard is.
  // [taak] is een functie die we hier pas uitvoeren, bv. () => contactRepository.bewaar(contact)
  Future<void> naarDatabase(Future<void> Function() taak) async {
    if (!bewaarInDatabase) return;
    try {
      await taak();
    } catch (fout) {
      debugPrint('Opslaan mislukt: $fout');
      foutmelding = 'Opslaan is niet gelukt. Controleer je internet en probeer opnieuw.';
      await laadAlles();
    }
  }

  // ---------- Contacten ----------

  // Voor een nieuw én een bewerkt contact.
  Future<void> bewaarContact(Contact contact) async {
    if (!contacten.contains(contact)) contacten.add(contact);
    notifyListeners();
    await naarDatabase(() => contactRepository.bewaar(contact));
  }

  Future<void> verwijderContact(Contact contact) async {
    contacten.remove(contact);
    relaties.removeWhere((relatie) => relatie.bevat(contact));
    notifyListeners();
    // Zijn bezoeken en relaties verdwijnen in de database automatisch mee.
    await naarDatabase(() => contactRepository.verwijder(contact));
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
  Future<void> voegRelatieToe(Contact a, Contact b, {bool bevestigd = true, String opmerking = '', Color? kleur}) async {
    Relatie? relatie = relatieTussen(a, b);
    if (relatie != null) {
      relatie.bevestigd = bevestigd;
      relatie.opmerking = opmerking;
      relatie.kleur = kleur;
    } else {
      relatie = Relatie(a, b, bevestigd: bevestigd, opmerking: opmerking, kleur: kleur);
      relaties.add(relatie);
    }
    notifyListeners();
    Relatie teBewaren = relatie;
    await naarDatabase(() => relatieRepository.bewaar(teBewaren));
  }

  Future<void> verwijderRelatie(Relatie relatie) async {
    relaties.remove(relatie);
    notifyListeners();
    await naarDatabase(() => relatieRepository.verwijder(relatie));
  }

  // Zorgt dat [contact] precies met deze [partners] verbonden is.
  Future<void> zetPartners(Contact contact, List<Contact> partners) async {
    List<Relatie> teVerwijderen = [];
    for (Relatie relatie in relaties) {
      if (relatie.bevat(contact) && !partners.contains(relatie.ander(contact))) {
        teVerwijderen.add(relatie);
      }
    }
    List<Relatie> nieuw = [];
    for (Contact partner in partners) {
      if (relatieTussen(contact, partner) == null) {
        nieuw.add(Relatie(contact, partner));
      }
    }

    for (Relatie relatie in teVerwijderen) {
      relaties.remove(relatie);
    }
    relaties.addAll(nieuw);
    notifyListeners();

    await naarDatabase(() async {
      for (Relatie relatie in teVerwijderen) {
        await relatieRepository.verwijder(relatie);
      }
      for (Relatie relatie in nieuw) {
        await relatieRepository.bewaar(relatie);
      }
    });
  }

  // ---------- Bezoeken ----------

  // Voegt een bezoek toe en past meteen de interesse van het contact aan.
  Future<void> voegBezoekToe(Contact contact, Bezoek bezoek) async {
    contact.bezoeken.add(bezoek);
    sorteerBezoeken(contact);
    if (contact.laatsteBezoek == bezoek) {
      contact.interesse = bezoek.interesseNa;
    }
    notifyListeners();
    await naarDatabase(() async {
      await bezoekRepository.bewaar(contact, bezoek);
      await contactRepository.bewaar(contact); // de interesse kan veranderd zijn
    });
  }

  Future<void> verwijderBezoek(Contact contact, Bezoek bezoek) async {
    contact.bezoeken.remove(bezoek);
    notifyListeners();
    await naarDatabase(() => bezoekRepository.verwijder(bezoek));
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
      if (leden.length >= 2) resultaat.add(Keten(contact, leden, ketenNaamVan(contact)));
    }
    return resultaat;
  }

  // De naam van de keten rond [middelpunt]: de zelfgekozen naam, of "Keten van ...".
  String ketenNaamVan(Contact middelpunt) {
    if (middelpunt.ketenNaam.isNotEmpty) return middelpunt.ketenNaam;
    return 'Keten van ${middelpunt.naam}';
  }

  // Een lege naam = terug naar de standaardnaam.
  // De naam wordt bewaard bij het middelpunt (de chirurg), want de ketens zelf
  // worden telkens opnieuw berekend.
  Future<void> zetKetenNaam(Contact middelpunt, String naam) async {
    middelpunt.ketenNaam = naam.trim();
    notifyListeners();
    await naarDatabase(() => contactRepository.bewaar(middelpunt));
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
