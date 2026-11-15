// Hier staat hoe een contact en een relatie eruitzien.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Het soort contact. Dit bepaalt de vorm op de kaart.
enum Soort { chirurg, tandarts, labo }

// Hoe geïnteresseerd iemand is in Bego. Dit bepaalt de kleur op de kaart.
enum Interesse { gebruiktBego, geinteresseerd, twijfelt, nietGeinteresseerd, nietBenaderd }

class Contact {
  String naam;
  Soort soort;
  Interesse interesse;
  String adres;
  LatLng plaats; // de plek op de kaart (breedtegraad, lengtegraad)
  String praktijk; // mag leeg zijn
  String merk; // huidig implantaatmerk, mag leeg zijn
  String opmerking; // mag leeg zijn

  Contact({
    required this.naam,
    required this.soort,
    required this.interesse,
    required this.adres,
    required this.plaats,
    this.praktijk = '',
    this.merk = '',
    this.opmerking = '',
  });
}

// Twee contacten die samenwerken.
class Relatie {
  Contact eerste;
  Contact tweede;
  bool bevestigd; // false = "ik denk dat ze samenwerken" (stippellijn)

  Relatie(this.eerste, this.tweede, {this.bevestigd = true});

  bool bevat(Contact contact) {
    return eerste == contact || tweede == contact;
  }
}

// Geeft alle contacten terug die samenwerken met [contact].
List<Contact> zoekPartners(Contact contact, List<Relatie> relaties) {
  List<Contact> partners = [];
  for (Relatie relatie in relaties) {
    if (relatie.eerste == contact) {
      partners.add(relatie.tweede);
    }
    if (relatie.tweede == contact) {
      partners.add(relatie.eerste);
    }
  }
  return partners;
}

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
      return Colors.green.shade800;
    case Interesse.geinteresseerd:
      return Colors.lightGreen;
    case Interesse.twijfelt:
      return Colors.orange;
    case Interesse.nietGeinteresseerd:
      return Colors.red;
    case Interesse.nietBenaderd:
      return Colors.grey;
  }
}
