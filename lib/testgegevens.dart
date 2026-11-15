// Verzonnen contacten om de app te testen. Later komt dit uit een database.

import 'package:latlong2/latlong.dart';

import 'contact.dart';

Contact janssens = Contact(
  naam: 'Chirurg Janssens',
  soort: Soort.chirurg,
  interesse: Interesse.gebruiktBego,
  adres: 'Ziekenhuislaan 1, 9700 Oudenaarde',
  plaats: LatLng(50.845, 3.605),
  merk: 'Bego',
);

Contact peeters = Contact(
  naam: 'Dr. An Peeters',
  soort: Soort.tandarts,
  interesse: Interesse.gebruiktBego,
  adres: 'Markt 12, 9700 Oudenaarde',
  plaats: LatLng(50.85, 3.62),
  praktijk: 'Tandartspraktijk De Linde',
  opmerking: 'Enkel bereikbaar op dinsdag',
);

Contact dentalab = Contact(
  naam: 'Labo Dentalab',
  soort: Soort.labo,
  interesse: Interesse.twijfelt,
  adres: 'Industrieweg 5, 9500 Geraardsbergen',
  plaats: LatLng(50.77, 3.88),
  merk: 'Straumann',
  opmerking: 'Wil eerst een demo van de scanner',
);

Contact deVos = Contact(
  naam: 'Chirurg De Vos',
  soort: Soort.chirurg,
  interesse: Interesse.twijfelt,
  adres: 'Kouter 3, 9000 Gent',
  plaats: LatLng(51.05, 3.72),
  merk: 'Nobel Biocare',
);

Contact maes = Contact(
  naam: 'Dr. Tom Maes',
  soort: Soort.tandarts,
  interesse: Interesse.geinteresseerd,
  adres: 'Stationsstraat 8, 9300 Aalst',
  plaats: LatLng(50.94, 4.04),
);

Contact claes = Contact(
  naam: 'Dr. Sara Claes',
  soort: Soort.tandarts,
  interesse: Interesse.nietGeinteresseerd,
  adres: 'Grote Markt 2, 8500 Kortrijk',
  plaats: LatLng(50.83, 3.265),
  merk: 'Straumann',
);

Contact smileLab = Contact(
  naam: 'Smile Lab',
  soort: Soort.labo,
  interesse: Interesse.nietBenaderd,
  adres: 'Nijverheidsstraat 20, 9800 Deinze',
  plaats: LatLng(50.98, 3.53),
);

List<Contact> alleContacten = [janssens, peeters, dentalab, deVos, maes, claes, smileLab];

List<Relatie> alleRelaties = [
  Relatie(janssens, peeters),
  Relatie(peeters, dentalab),
  Relatie(janssens, dentalab),
  Relatie(deVos, maes),
  Relatie(deVos, peeters),
  Relatie(maes, smileLab, bevestigd: false),
  Relatie(claes, smileLab, bevestigd: false),
];
