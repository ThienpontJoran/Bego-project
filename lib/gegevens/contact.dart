// Hoe een contact, een bezoek en een relatie eruitzien,
// plus de teksten en kleuren die bij elk type en elke interesse horen.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Het soort contact. Dit bepaalt de vorm op de kaart.
enum Soort { chirurg, tandarts, labo }

// Hoe ver iemand mee is met Bego. Dit bepaalt de kleur op de kaart.
enum Interesse { gebruiktBego, geinteresseerd, twijfelt, nietGeinteresseerd, nietBenaderd }

// Hoe je iemand gesproken hebt.
enum Contactmoment { bezoek, telefoon, email, beurs }

class Bezoek {
  DateTime datum;
  Contactmoment soort;
  String verslag;
  String volgendeStap; // leeg = geen volgende stap
  DateTime? volgendeStapDatum; // null = geen datum gekozen
  Interesse interesseNa;

  Bezoek({
    required this.datum,
    required this.soort,
    required this.interesseNa,
    this.verslag = '',
    this.volgendeStap = '',
    this.volgendeStapDatum,
  });
}

class Contact {
  Soort soort;
  String naam;
  String praktijk; // leeg = niet ingevuld
  String adres;
  LatLng plaats; // de plek op de kaart
  String telefoon;
  String email;
  List<String> merken; // huidige implantaatmerken
  Interesse interesse;
  String opmerking;
  List<Bezoek> bezoeken = []; // het nieuwste bezoek staat vooraan

  Contact({
    required this.soort,
    required this.naam,
    required this.adres,
    required this.plaats,
    required this.interesse,
    this.praktijk = '',
    this.telefoon = '',
    this.email = '',
    this.merken = const [],
    this.opmerking = '',
  });

  // Een "get" werkt zoals een property in C#: je gebruikt het als contact.laatsteBezoek
  Bezoek? get laatsteBezoek {
    if (bezoeken.isEmpty) return null;
    return bezoeken.first;
  }

  // Aantal dagen sinds het laatste bezoek, of null als hij nog nooit bezocht is.
  int? get dagenNietBezocht {
    Bezoek? laatste = laatsteBezoek;
    if (laatste == null) return null;
    return DateTime.now().difference(laatste.datum).inDays;
  }

  // Langer dan 3 maanden niet bezocht (of nooit, maar wel al benaderd).
  bool get langNietBezocht {
    if (interesse == Interesse.nietBenaderd) return false;
    int? dagen = dagenNietBezocht;
    if (dagen == null) return true;
    return dagen > 90;
  }
}

// Twee contacten die samen patiënten behandelen. Werkt in beide richtingen.
class Relatie {
  Contact eerste;
  Contact tweede;
  bool bevestigd; // false = "ik denk dat ze samenwerken" (stippellijn)
  String opmerking;

  Relatie(this.eerste, this.tweede, {this.bevestigd = true, this.opmerking = ''});

  bool bevat(Contact contact) {
    return eerste == contact || tweede == contact;
  }

  // Geeft de andere kant van de relatie.
  Contact ander(Contact contact) {
    if (eerste == contact) return tweede;
    return eerste;
  }
}

// ---------- Teksten en kleuren ----------

String soortTekst(Soort soort) {
  switch (soort) {
    case Soort.chirurg:
      return 'Chirurg';
    case Soort.tandarts:
      return 'Tandarts';
    case Soort.labo:
      return 'Labo';
  }
}

String soortMeervoud(Soort soort) {
  switch (soort) {
    case Soort.chirurg:
      return 'Chirurgen';
    case Soort.tandarts:
      return 'Tandartsen';
    case Soort.labo:
      return "Labo's";
  }
}

String interesseTekst(Interesse interesse) {
  switch (interesse) {
    case Interesse.gebruiktBego:
      return 'Gebruikt Bego';
    case Interesse.geinteresseerd:
      return 'Geïnteresseerd';
    case Interesse.twijfelt:
      return 'Twijfelt';
    case Interesse.nietGeinteresseerd:
      return 'Niet geïnteresseerd';
    case Interesse.nietBenaderd:
      return 'Nog niet benaderd';
  }
}

Color interesseKleur(Interesse interesse) {
  switch (interesse) {
    case Interesse.gebruiktBego:
      return const Color(0xFF2E7D32); // groen
    case Interesse.geinteresseerd:
      return const Color(0xFF8BC34A); // lichtgroen
    case Interesse.twijfelt:
      return const Color(0xFFFB8C00); // oranje
    case Interesse.nietGeinteresseerd:
      return const Color(0xFFE53935); // rood
    case Interesse.nietBenaderd:
      return const Color(0xFF9E9E9E); // grijs
  }
}

String contactmomentTekst(Contactmoment moment) {
  switch (moment) {
    case Contactmoment.bezoek:
      return 'Bezoek';
    case Contactmoment.telefoon:
      return 'Telefoon';
    case Contactmoment.email:
      return 'E-mail';
    case Contactmoment.beurs:
      return 'Beurs';
  }
}

IconData contactmomentIcoon(Contactmoment moment) {
  switch (moment) {
    case Contactmoment.bezoek:
      return Icons.directions_car_outlined;
    case Contactmoment.telefoon:
      return Icons.phone_outlined;
    case Contactmoment.email:
      return Icons.mail_outline;
    case Contactmoment.beurs:
      return Icons.storefront_outlined;
  }
}
