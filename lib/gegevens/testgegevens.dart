// Verzonnen contacten om de app te testen. Namen en gegevens bestaan niet echt.

import 'package:latlong2/latlong.dart';

import 'contact.dart';
import 'opslag.dart';

void vulTestgegevens(Opslag opslag) {
  // ---------- Chirurgen ----------
  Contact janssens = Contact(
    soort: Soort.chirurg,
    naam: 'Dr. Koen Janssens',
    praktijk: 'Kaakchirurgie Scheldevallei',
    adres: 'Ziekenhuisstraat 4, 9700 Oudenaarde',
    plaats: LatLng(50.842, 3.598),
    telefoon: '055 11 22 33',
    email: 'k.janssens@voorbeeld.be',
    merken: ['Bego', 'Straumann'],
    interesse: Interesse.gebruiktBego,
    opmerking: 'Opereert op maandag en donderdag.',
  );
  Contact deVos = Contact(
    soort: Soort.chirurg,
    naam: 'Dr. Els De Vos',
    praktijk: 'MKA Gent Centrum',
    adres: 'Kouter 30, 9000 Gent',
    plaats: LatLng(51.049, 3.726),
    telefoon: '09 222 33 44',
    merken: ['Nobel Biocare'],
    interesse: Interesse.twijfelt,
    opmerking: 'Wil cijfers zien over osseo-integratie.',
  );
  Contact willems = Contact(
    soort: Soort.chirurg,
    naam: 'Dr. Pieter Willems',
    adres: 'Dendermondsesteenweg 50, 9300 Aalst',
    plaats: LatLng(50.945, 4.045),
    merken: ['Straumann'],
    interesse: Interesse.geinteresseerd,
  );
  Contact vandamme = Contact(
    soort: Soort.chirurg,
    naam: 'Dr. Marc Vandamme',
    adres: 'Doorniksewijk 10, 8500 Kortrijk',
    plaats: LatLng(50.820, 3.270),
    merken: ['Straumann'],
    interesse: Interesse.nietGeinteresseerd,
    opmerking: 'Tevreden met Straumann, niet aandringen.',
  );
  Contact lambrecht = Contact(
    soort: Soort.chirurg,
    naam: 'Dr. Sofie Lambrecht',
    adres: 'Langestraat 15, 8000 Brugge',
    plaats: LatLng(51.209, 3.234),
    interesse: Interesse.nietBenaderd,
  );

  // ---------- Tandartsen ----------
  Contact peeters = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. An Peeters',
    praktijk: 'Tandartspraktijk De Linde',
    adres: 'Markt 12, 9700 Oudenaarde',
    plaats: LatLng(50.849, 3.607),
    telefoon: '055 12 34 56',
    email: 'info@delinde-voorbeeld.be',
    merken: ['Bego'],
    interesse: Interesse.gebruiktBego,
    opmerking: 'Enkel bereikbaar op dinsdag.',
  );
  Contact maes = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Tom Maes',
    adres: 'Stationsstraat 8, 9300 Aalst',
    plaats: LatLng(50.940, 4.030),
    merken: ['Straumann'],
    interesse: Interesse.geinteresseerd,
  );
  Contact claes = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Sara Claes',
    adres: 'Grote Markt 2, 8500 Kortrijk',
    plaats: LatLng(50.828, 3.265),
    merken: ['Straumann'],
    interesse: Interesse.nietGeinteresseerd,
  );
  Contact desmet = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Lies Desmet',
    praktijk: 'Tandzorg Ronse',
    adres: 'Grote Markt 20, 9600 Ronse',
    plaats: LatLng(50.746, 3.600),
    merken: ['Bego'],
    interesse: Interesse.gebruiktBego,
  );
  Contact vermeulen = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Bram Vermeulen',
    adres: 'Heldenlaan 5, 9620 Zottegem',
    plaats: LatLng(50.869, 3.811),
    merken: ['Dentsply'],
    interesse: Interesse.twijfelt,
  );
  Contact goossens = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Nina Goossens',
    praktijk: 'Groepspraktijk Sint-Pieters',
    adres: 'Sint-Pietersnieuwstraat 100, 9000 Gent',
    plaats: LatLng(51.042, 3.722),
    merken: ['Bego', 'Nobel Biocare'],
    interesse: Interesse.gebruiktBego,
  );
  Contact martens = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Jonas Martens',
    adres: 'Markt 3, 9800 Deinze',
    plaats: LatLng(50.983, 3.528),
    interesse: Interesse.nietBenaderd,
  );
  Contact wouters = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Eva Wouters',
    adres: 'Oudenaardsestraat 40, 9500 Geraardsbergen',
    plaats: LatLng(50.776, 3.872),
    merken: ['Bego'],
    interesse: Interesse.gebruiktBego,
  );

  // ---------- Een kleine keten die al volledig Bego is ----------
  Contact coppens = Contact(
    soort: Soort.chirurg,
    naam: 'Dr. Hilde Coppens',
    adres: 'Stationsplein 2, 9900 Eeklo',
    plaats: LatLng(51.183, 3.563),
    merken: ['Bego'],
    interesse: Interesse.gebruiktBego,
  );
  Contact dhondt = Contact(
    soort: Soort.tandarts,
    naam: 'Dr. Wim Dhondt',
    adres: 'Markt 10, 9900 Eeklo',
    plaats: LatLng(51.186, 3.558),
    merken: ['Bego'],
    interesse: Interesse.gebruiktBego,
  );
  Contact meetjesland = Contact(
    soort: Soort.labo,
    naam: 'Labo Meetjesland',
    adres: 'Industrielaan 3, 9990 Maldegem',
    plaats: LatLng(51.207, 3.447),
    merken: ['Bego'],
    interesse: Interesse.gebruiktBego,
  );

  // ---------- Labo's ----------
  Contact dentalab = Contact(
    soort: Soort.labo,
    naam: 'Labo Dentalab',
    adres: 'Industrieweg 5, 9500 Geraardsbergen',
    plaats: LatLng(50.768, 3.890),
    telefoon: '054 41 41 41',
    merken: ['Straumann'],
    interesse: Interesse.twijfelt,
    opmerking: 'Wil eerst een demo van de scanner.',
  );
  Contact smileLab = Contact(
    soort: Soort.labo,
    naam: 'Smile Lab',
    adres: 'Nijverheidsstraat 20, 9800 Deinze',
    plaats: LatLng(50.976, 3.540),
    interesse: Interesse.nietBenaderd,
  );
  Contact verhaeghe = Contact(
    soort: Soort.labo,
    naam: 'Tandtechniek Verhaeghe',
    adres: 'Stationsplein 7, 8790 Waregem',
    plaats: LatLng(50.889, 3.427),
    merken: ['Bego'],
    interesse: Interesse.gebruiktBego,
  );
  Contact kroonBrug = Contact(
    soort: Soort.labo,
    naam: 'Kroon & Brug',
    adres: 'Dok Noord 4, 9000 Gent',
    plaats: LatLng(51.066, 3.735),
    merken: ['Bego', 'Straumann'],
    interesse: Interesse.gebruiktBego,
  );
  Contact scheldeland = Contact(
    soort: Soort.labo,
    naam: 'Labo Scheldeland',
    adres: 'Markt 1, 9230 Wetteren',
    plaats: LatLng(51.004, 3.883),
    merken: ['Nobel Biocare'],
    interesse: Interesse.nietGeinteresseerd,
  );

  opslag.contacten.addAll([
    janssens, deVos, willems, vandamme, lambrecht, coppens,
    peeters, maes, claes, desmet, vermeulen, goossens, martens, wouters, dhondt,
    dentalab, smileLab, verhaeghe, kroonBrug, scheldeland, meetjesland,
  ]);

  // ---------- Relaties ----------
  opslag.voegRelatieToe(janssens, peeters, opmerking: 'Stuurt vooral sinusliften door');
  opslag.voegRelatieToe(peeters, dentalab);
  opslag.voegRelatieToe(janssens, dentalab);
  opslag.voegRelatieToe(janssens, desmet);
  opslag.voegRelatieToe(desmet, verhaeghe);
  opslag.voegRelatieToe(janssens, wouters);
  opslag.voegRelatieToe(wouters, dentalab);
  opslag.voegRelatieToe(deVos, goossens);
  opslag.voegRelatieToe(goossens, kroonBrug);
  opslag.voegRelatieToe(willems, goossens, bevestigd: false);
  opslag.voegRelatieToe(willems, maes);
  opslag.voegRelatieToe(maes, scheldeland);
  opslag.voegRelatieToe(willems, vermeulen);
  opslag.voegRelatieToe(vermeulen, dentalab);
  opslag.voegRelatieToe(vandamme, claes);
  opslag.voegRelatieToe(claes, verhaeghe);
  opslag.voegRelatieToe(martens, smileLab, bevestigd: false); // tandarts zonder chirurg
  opslag.voegRelatieToe(coppens, dhondt);
  opslag.voegRelatieToe(dhondt, meetjesland);

  // ---------- Bezoeken ----------
  voegBezoekToe(opslag, janssens, 20, Contactmoment.bezoek,
      'Tevreden over de nieuwe implantaatlijn. Vraagt of Dentalab al mee is.');
  voegBezoekToe(opslag, janssens, 140, Contactmoment.beurs, 'Kort gesproken op de beurs in Gent.');
  voegBezoekToe(opslag, peeters, 35, Contactmoment.bezoek, 'Scans lopen goed.');
  voegBezoekToe(opslag, dentalab, 120, Contactmoment.bezoek,
      'Positief over de scanner, wil eerst met Dr. Janssens overleggen.',
      volgendeStap: 'Demo scanner inplannen', stapOverDagen: 3);
  voegBezoekToe(opslag, deVos, 200, Contactmoment.telefoon, 'Twijfelt, wil studies zien.');
  voegBezoekToe(opslag, goossens, 15, Contactmoment.bezoek, 'Alles in orde.');
  voegBezoekToe(opslag, kroonBrug, 60, Contactmoment.email, 'Nieuwe prijslijst doorgestuurd.');
  voegBezoekToe(opslag, willems, 8, Contactmoment.bezoek, 'Enthousiast na de demo.',
      volgendeStap: 'Offerte sturen', stapOverDagen: -2);
  voegBezoekToe(opslag, maes, 45, Contactmoment.telefoon, 'Wacht op Dr. Willems.');
  voegBezoekToe(opslag, claes, 300, Contactmoment.bezoek, 'Niet geïnteresseerd.');
  voegBezoekToe(opslag, desmet, 100, Contactmoment.bezoek, 'Vaste klant, geen problemen.');
  voegBezoekToe(opslag, verhaeghe, 25, Contactmoment.bezoek, 'Bestelling geplaatst.');
  voegBezoekToe(opslag, vermeulen, 95, Contactmoment.bezoek, 'Heeft bezwaren over de prijs.',
      volgendeStap: 'Terugbellen met kortingsvoorstel', stapOverDagen: 12);
  voegBezoekToe(opslag, wouters, 12, Contactmoment.bezoek, 'Wil een proefpakket.');
  voegBezoekToe(opslag, coppens, 30, Contactmoment.bezoek, 'Hele keten werkt nu met Bego.');
  voegBezoekToe(opslag, dhondt, 30, Contactmoment.telefoon, 'Tevreden.');
  voegBezoekToe(opslag, meetjesland, 50, Contactmoment.email, 'Bestelling bevestigd.');
}

// Hulpfunctie: voegt een bezoek toe van [dagenGeleden] dagen geleden.
// De interesse blijft wat ze nu is.
void voegBezoekToe(
  Opslag opslag,
  Contact contact,
  int dagenGeleden,
  Contactmoment soort,
  String verslag, {
  String volgendeStap = '',
  int? stapOverDagen,
}) {
  DateTime nu = DateTime.now();
  DateTime? stapDatum;
  if (stapOverDagen != null) {
    stapDatum = nu.add(Duration(days: stapOverDagen));
  }
  Bezoek bezoek = Bezoek(
    datum: nu.subtract(Duration(days: dagenGeleden)),
    soort: soort,
    verslag: verslag,
    volgendeStap: volgendeStap,
    volgendeStapDatum: stapDatum,
    interesseNa: contact.interesse,
  );
  opslag.voegBezoekToe(contact, bezoek);
}
