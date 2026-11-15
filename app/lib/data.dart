import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum ContactType {
  chirurg('Chirurg'),
  tandarts('Tandarts'),
  labo('Labo');

  const ContactType(this.label);
  final String label;
}

enum Interest {
  gebruiktBego('Gebruikt Bego', Color(0xFF2E7D32)),
  geinteresseerd('Geïnteresseerd', Color(0xFF9CCC65)),
  twijfelt('Twijfelt', Color(0xFFFFA726)),
  nietGeinteresseerd('Niet geïnteresseerd', Color(0xFFE53935)),
  nietBenaderd('Nog niet benaderd', Color(0xFF9E9E9E));

  const Interest(this.label, this.color);
  final String label;
  final Color color;
}

class Contact {
  const Contact({
    required this.type,
    required this.name,
    required this.address,
    required this.location,
    required this.interest,
    this.practice,
    this.brand,
    this.notes,
  });

  final ContactType type;
  final String name;
  final String address;
  final LatLng location;
  final Interest interest;
  final String? practice;
  final String? brand;
  final String? notes;
}

class Relation {
  const Relation(this.a, this.b, {this.confirmed = true});
  final Contact a;
  final Contact b;
  final bool confirmed;
}

List<Contact> partnersOf(Contact c) => [
      for (final r in relations)
        if (r.a == c) r.b else if (r.b == c) r.a,
    ];

// Fictieve testgegevens: nog geen echte personen of database.
const _janssens = Contact(
  type: ContactType.chirurg,
  name: 'Chirurg Janssens',
  address: 'Ziekenhuislaan 1, 9700 Oudenaarde',
  location: LatLng(50.845, 3.605),
  interest: Interest.gebruiktBego,
  brand: 'Bego',
);
const _peeters = Contact(
  type: ContactType.tandarts,
  name: 'Dr. An Peeters',
  practice: 'Tandartspraktijk De Linde',
  address: 'Markt 12, 9700 Oudenaarde',
  location: LatLng(50.85, 3.62),
  interest: Interest.gebruiktBego,
  notes: 'Enkel bereikbaar op dinsdag',
);
const _dentalab = Contact(
  type: ContactType.labo,
  name: 'Labo Dentalab',
  address: 'Industrieweg 5, 9500 Geraardsbergen',
  location: LatLng(50.77, 3.88),
  interest: Interest.twijfelt,
  brand: 'Straumann',
  notes: 'Wil eerst een demo van de scanner',
);
const _devos = Contact(
  type: ContactType.chirurg,
  name: 'Chirurg De Vos',
  address: 'Kouter 3, 9000 Gent',
  location: LatLng(51.05, 3.72),
  interest: Interest.twijfelt,
  brand: 'Nobel Biocare',
);
const _maes = Contact(
  type: ContactType.tandarts,
  name: 'Dr. Tom Maes',
  address: 'Stationsstraat 8, 9300 Aalst',
  location: LatLng(50.94, 4.04),
  interest: Interest.geinteresseerd,
);
const _claes = Contact(
  type: ContactType.tandarts,
  name: 'Dr. Sara Claes',
  address: 'Grote Markt 2, 8500 Kortrijk',
  location: LatLng(50.83, 3.265),
  interest: Interest.nietGeinteresseerd,
  brand: 'Straumann',
);
const _smilelab = Contact(
  type: ContactType.labo,
  name: 'Smile Lab',
  address: 'Nijverheidsstraat 20, 9800 Deinze',
  location: LatLng(50.98, 3.53),
  interest: Interest.nietBenaderd,
);

const contacts = [_janssens, _peeters, _dentalab, _devos, _maes, _claes, _smilelab];

const relations = [
  Relation(_janssens, _peeters),
  Relation(_peeters, _dentalab),
  Relation(_janssens, _dentalab),
  Relation(_devos, _maes),
  Relation(_maes, _smilelab, confirmed: false),
  Relation(_devos, _peeters),
  Relation(_claes, _smilelab, confirmed: false),
];
