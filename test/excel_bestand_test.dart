// Test of het Excel-bestand de contacten en relaties bevat.

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bego_netwerkkaart/models/contact.dart';
import 'package:bego_netwerkkaart/models/relatie.dart';
import 'package:bego_netwerkkaart/services/excel_bestand.dart';

void main() {
  test('het Excel-bestand heeft een tabblad met contacten en een met relaties', () {
    Contact a = Contact(soort: Soort.tandarts, naam: 'Dr. Één', adres: 'Kerkstraat 1, Gent',
        plaats: const LatLng(51.05, 3.72), interesse: Interesse.geinteresseerd);
    Contact b = Contact(soort: Soort.labo, naam: 'Labo Twee', adres: 'Markt 2, Brugge',
        plaats: const LatLng(51.21, 3.22), interesse: Interesse.gebruiktBego);
    Relatie relatie = Relatie(a, b, bevestigd: false);

    // Maak het bestand en lees het daarna terug in.
    Excel excel = Excel.decodeBytes(maakExcel([a, b], [relatie]));

    Sheet contacten = excel['Contacten'];
    expect(contacten.maxRows, 3); // kopjes + 2 contacten
    expect(contacten.cell(CellIndex.indexByString('A2')).value.toString(), 'Dr. Één');
    expect(contacten.cell(CellIndex.indexByString('H2')).value.toString(), 'Geïnteresseerd');

    Sheet relaties = excel['Relaties'];
    expect(relaties.maxRows, 2); // kopjes + 1 relatie
    expect(relaties.cell(CellIndex.indexByString('B2')).value.toString(), 'Labo Twee');
    expect(relaties.cell(CellIndex.indexByString('C2')).value.toString(), 'Nee');
  });
}
