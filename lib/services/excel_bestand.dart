// Maakt een Excel-bestand (.xlsx) met alle contacten en relaties.
// Het bestand heeft twee tabbladen: "Contacten" en "Relaties".

import 'package:excel/excel.dart';

import '../models/contact.dart';
import '../models/relatie.dart';
import '../utils/hulpfuncties.dart';

// Geeft de inhoud van het Excel-bestand terug (als een lijst bytes).
List<int> maakExcel(List<Contact> contacten, List<Relatie> relaties) {
  Excel excel = Excel.createExcel(); // begint met één leeg tabblad "Sheet1"
  excel.rename('Sheet1', 'Contacten');

  // ---------- Tabblad "Contacten" ----------
  Sheet blad = excel['Contacten'];
  voegKoppenToe(blad, [
    'Naam', 'Soort', 'Praktijk', 'Adres', 'Telefoon', 'E-mail', 'Merken',
    'Interesse', 'Laatste bezoek', 'Opmerking', 'Breedtegraad', 'Lengtegraad',
  ]);
  for (Contact contact in contacten) {
    String laatsteBezoek = '';
    if (contact.laatsteBezoek != null) laatsteBezoek = datumTekst(contact.laatsteBezoek!.datum);
    blad.appendRow([
      TextCellValue(contact.naam),
      TextCellValue(soortTekst(contact.soort)),
      TextCellValue(contact.praktijk),
      TextCellValue(contact.adres),
      TextCellValue(contact.telefoon),
      TextCellValue(contact.email),
      TextCellValue(contact.merken.join(', ')),
      TextCellValue(interesseTekst(contact.interesse)),
      TextCellValue(laatsteBezoek),
      TextCellValue(contact.opmerking),
      DoubleCellValue(contact.plaats.latitude),
      DoubleCellValue(contact.plaats.longitude),
    ]);
  }

  // ---------- Tabblad "Relaties" ----------
  Sheet relatieBlad = excel['Relaties']; // bestaat nog niet: wordt nu gemaakt
  voegKoppenToe(relatieBlad, ['Contact 1', 'Contact 2', 'Bevestigd', 'Opmerking']);
  for (Relatie relatie in relaties) {
    relatieBlad.appendRow([
      TextCellValue(relatie.eerste.naam),
      TextCellValue(relatie.tweede.naam),
      TextCellValue(relatie.bevestigd ? 'Ja' : 'Nee'),
      TextCellValue(relatie.opmerking),
    ]);
  }

  return excel.encode()!;
}

// Zet de kolomnamen in het vet op de eerste rij en maakt de kolommen wat breder.
void voegKoppenToe(Sheet blad, List<String> koppen) {
  List<CellValue> rij = [];
  for (String kop in koppen) {
    rij.add(TextCellValue(kop));
  }
  blad.appendRow(rij);
  for (int kolom = 0; kolom < koppen.length; kolom++) {
    blad.cell(CellIndex.indexByColumnRow(columnIndex: kolom, rowIndex: 0)).cellStyle = CellStyle(bold: true);
    blad.setColumnWidth(kolom, 22);
  }
}
