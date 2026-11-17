// Hoe een contact eruitziet, plus de teksten en kleuren die bij elk type en elke interesse horen.
// Een contact wordt bewaard in de tabel "contacten" in Supabase.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'bezoek.dart';

// Het soort contact. Dit bepaalt de vorm op de kaart.
enum Soort { chirurg, tandarts, labo }

// Hoe ver iemand mee is met Bego. Dit bepaalt de kleur op de kaart.
enum Interesse { gebruiktBego, geinteresseerd, twijfelt, nietGeinteresseerd, nietBenaderd }

class Contact {
  String id; // uniek nummer in de database, bv. "3f2b9c1e-..."
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
  String ketenNaam; // zelfgekozen naam van de keten rond dit contact (leeg = standaardnaam)
  List<Bezoek> bezoeken = []; // het nieuwste bezoek staat vooraan

  // Geef je geen id mee, dan maken we zelf een nieuw, uniek id.
  // ("??" betekent: gebruik het rechtse als het linkse null is.)
  Contact({
    String? id,
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
    this.ketenNaam = '',
  }) : id = id ?? const Uuid().v4();

  // ---------- Van en naar de database ----------

  // Maakt een contact uit een rij van de tabel "contacten".
  // Een enum bewaren we als tekst, bv. Soort.chirurg -> "chirurg".
  static Contact vanDatabase(Map<String, dynamic> rij) {
    return Contact(
      id: rij['id'],
      soort: Soort.values.byName(rij['soort']),
      naam: rij['naam'],
      praktijk: rij['praktijk'],
      adres: rij['adres'],
      // "as num" + toDouble(): de database kan 51 sturen in plaats van 51.0.
      plaats: LatLng((rij['breedtegraad'] as num).toDouble(), (rij['lengtegraad'] as num).toDouble()),
      telefoon: rij['telefoon'],
      email: rij['email'],
      merken: List<String>.from(rij['merken']),
      interesse: Interesse.values.byName(rij['interesse']),
      opmerking: rij['opmerking'],
      ketenNaam: rij['keten_naam'],
    );
  }

  // Zet het contact om naar een rij voor de tabel "contacten".
  Map<String, dynamic> naarDatabase() {
    return {
      'id': id,
      'soort': soort.name,
      'naam': naam,
      'praktijk': praktijk,
      'adres': adres,
      'breedtegraad': plaats.latitude,
      'lengtegraad': plaats.longitude,
      'telefoon': telefoon,
      'email': email,
      'merken': merken,
      'interesse': interesse.name,
      'opmerking': opmerking,
      'keten_naam': ketenNaam,
    };
  }

  // ---------- Handige eigenschappen ----------

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
