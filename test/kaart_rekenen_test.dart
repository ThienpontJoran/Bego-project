// Tests voor het rekenwerk van de kaart (uitwaaieren en bogen).


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
LatLng naarPlaats(Offset punt) => LatLng(punt.dy / 1000, punt.dx / 1000);

void main() {
  test('contacten op hetzelfde adres worden uit elkaar gezet', () {
    Contact a = maakContact('A', 50.000, 3.000);
    Contact b = maakContact('B', 50.000, 3.000); // zelfde adres als A
    Contact c = maakContact('C', 51.000, 3.000); // ver weg
    Map<Contact, LatLng> plekken = uitgewaaierdePlekken([a, b, c], naarPixels, naarPlaats, 30);
    // A en B staan nu (bijna) 30 pixels uit elkaar.
    double afstand = (naarPixels(plekken[a]!) - naarPixels(plekken[b]!)).distance;
    expect(afstand, closeTo(30, 0.01));
    // C ligt alleen en blijft gewoon op zijn adres.
    expect(plekken[c], c.plaats);
  });

  test('een rij icoontjes vlak bij elkaar overlapt daarna nergens meer', () {
    List<Contact> rij = [];
    for (int i = 0; i < 8; i++) {
      rij.add(maakContact('$i', 50.000, 3.000 + i * 0.005)); // telkens 5 pixels verder
    }
    Map<Contact, LatLng> plekken = uitgewaaierdePlekken(rij, naarPixels, naarPlaats, 30);
    for (int i = 0; i < rij.length; i++) {
      for (int j = i + 1; j < rij.length; j++) {
        double afstand = (naarPixels(plekken[rij[i]]!) - naarPixels(plekken[rij[j]]!)).distance;
        expect(afstand, greaterThan(29));
      }
    }
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

  test('een lijn die alleen loopt blijft recht', () {
    Contact a = maakContact('A', 50.800, 3.600);
    Contact z = maakContact('Z', 51.000, 4.000);
    Relatie relatie = Relatie(a, z);
    expect(bochtenVoor([relatie])[relatie], 0);
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
