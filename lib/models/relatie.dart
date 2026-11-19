// Twee contacten die samen patiënten behandelen. Werkt in beide richtingen.
// Een relatie wordt bewaard in de tabel "relaties" in Supabase.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'contact.dart';

class Relatie {
  String id; // uniek nummer in de database
  Contact eerste;
  Contact tweede;
  bool bevestigd; // false = "ik denk dat ze samenwerken" (stippellijn)
  String opmerking;
  Color? kleur; // eigen kleur voor de lijn op de kaart (null = standaard grijs)

  Relatie(this.eerste, this.tweede, {String? id, this.bevestigd = true, this.opmerking = '', this.kleur})
      : id = id ?? const Uuid().v4();

  bool bevat(Contact contact) {
    return eerste == contact || tweede == contact;
  }

  // Geeft de andere kant van de relatie.
  Contact ander(Contact contact) {
    if (eerste == contact) return tweede;
    return eerste;
  }

  // ---------- Naar de database ----------
  // (Het omgekeerde, een rij omzetten naar een relatie, gebeurt in RelatieRepository,
  // want daarvoor moet je de contacten al kennen.)

  // Een kleur bewaren we als getal, bv. 0xFF1E88E5.
  Map<String, dynamic> naarDatabase() {
    return {
      'id': id,
      'eerste_id': eerste.id,
      'tweede_id': tweede.id,
      'bevestigd': bevestigd,
      'opmerking': opmerking,
      'kleur': kleur?.toARGB32(),
    };
  }
}

// Kleuren die je aan een verbindingslijn kan geven.
// (Bewust geen groen/oranje/rood: die betekenen al iets bij de vormen.)
const List<Color> lijnKleuren = [
  Color(0xFF1E88E5), // blauw
  Color(0xFF8E24AA), // paars
  Color(0xFFD81B60), // roze
  Color(0xFF00897B), // blauwgroen
  Color(0xFF6D4C41), // bruin
  Color(0xFF212121), // zwart
  Color(0xFF4FC3F7), // lichtblauw
  Color(0xFF1A237E), // donkerblauw
  Color(0xFF26C6DA), // turkoois
  Color(0xFFCE93D8), // lila
  Color(0xFF4A148C), // donkerpaars
  Color(0xFFF06292), // lichtroze
  Color(0xFFFDD835), // geel
];
