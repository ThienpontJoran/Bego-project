// Tests voor het rekenwerk van de kaart (groepjes en bogen).


import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bego_netwerkkaart/models/contact.dart';
import 'package:bego_netwerkkaart/models/relatie.dart';
import 'package:bego_netwerkkaart/onderdelen/kaart_rekenen.dart';

Contact maakContact(String naam, double breedte, double lengte) {
  return Contact(
    soort: Soort.tandarts,
    naam: naam,
    adres: '',
    plaats: LatLng(breedte, lengte),
    interesse: Interesse.gebruiktBego,
  );
}

// Doet alsof 1 graad = 1000 pixels, zodat de test niet van de kaart afhangt.
Offset naarPixels(LatLng plaats) => Offset(plaats.longitude * 1000, plaats.latitude * 1000);

void main() {
  test('contacten dicht bij elkaar komen in één groepje', () {
    Contact a = maakContact('A', 50.000, 3.000);
    Contact b = maakContact('B', 50.000, 3.010); // 10 pixels verder
    Contact c = maakContact('C', 51.000, 3.000); // 1000 pixels verder
    List<List<Contact>> groepjes = groepeer([a, b, c], naarPixels, 30);
    expect(groepjes.length, 2);
    expect(groepjes[0], [a, b]);
    expect(groepjes[1], [c]);
  });

  test('een boog begint en eindigt op de contacten en wijkt in het midden af', () {
    LatLng van = LatLng(50.8, 3.6);
    LatLng naar = LatLng(50.8, 3.8);
    List<LatLng> punten = boog(van, naar, 0.2);
    expect(punten.first.latitude, closeTo(van.latitude, 0.0001));
    expect(punten.last.longitude, closeTo(naar.longitude, 0.0001));
    // Het midden ligt niet meer op de rechte lijn.
    expect((punten[10].latitude - 50.8).abs(), greaterThan(0.01));
  });

  test('twee lijnen naar dezelfde plek krijgen een andere bocht', () {
    Contact a = maakContact('A', 50.800, 3.600);
    Contact b = maakContact('B', 50.801, 3.601); // vlak naast A
    Contact z = maakContact('Z', 51.000, 4.000);
    Relatie eerste = Relatie(a, z);
    Relatie tweede = Relatie(z, b); // omgekeerd getekend
    Map<Relatie, double> bochten = bochtenVoor([eerste, tweede]);
    // Omgerekend naar dezelfde leesrichting moeten de bochten verschillen.
    double echteBocht(Relatie relatie) => bochten[relatie]! * (inLeesrichting(relatie) ? 1 : -1);
    expect(echteBocht(eerste), isNot(echteBocht(tweede)));
  });
}
