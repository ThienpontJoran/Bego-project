// Kleine tests. Uitvoeren met: .flutter\bin\flutter.bat test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bego_netwerkkaart/gegevens/adres_zoeker.dart';
import 'package:bego_netwerkkaart/gegevens/contact.dart';
import 'package:bego_netwerkkaart/gegevens/hulpfuncties.dart';
import 'package:bego_netwerkkaart/gegevens/keten.dart';
import 'package:bego_netwerkkaart/gegevens/opslag.dart';
import 'package:bego_netwerkkaart/main.dart';

Contact zoek(String naam) {
  return opslag.contacten.firstWhere((contact) => contact.naam == naam);
}

void main() {
  test('zoeken negeert hoofdletters, accenten en dubbele letters', () {
    Contact peeters = zoek('Dr. An Peeters');
    expect(pastBijZoekterm(peeters, 'peters'), true);
    expect(pastBijZoekterm(peeters, 'OUDENAARDE'), true);
    expect(pastBijZoekterm(peeters, 'Kortrijk'), false);
  });

  test('gemeente uit een adres halen', () {
    expect(gemeenteVan('Markt 12, 9700 Oudenaarde'), 'Oudenaarde');
  });

  test('partners werken in beide richtingen', () {
    List<Contact> partners = opslag.partnersVan(zoek('Labo Dentalab'));
    expect(partners, contains(zoek('Dr. An Peeters')));
  });

  test('ketens krijgen de juiste status', () {
    int volledig = 0;
    int bijna = 0;
    int open = 0;
    for (Keten keten in opslag.ketens) {
      if (keten.status == KetenStatus.volledig) volledig++;
      if (keten.status == KetenStatus.bijna) bijna++;
      if (keten.status == KetenStatus.open) open++;
    }
    expect(volledig, 1);
    expect(bijna, 2);
    expect(open, 3);
  });

  test('keten van een chirurg bevat al zijn tandartsen en hun labo\'s', () {
    Keten keten = opslag.ketens.firstWhere((k) => k.middelpunt == zoek('Dr. Koen Janssens'));
    // Janssens werkt met 3 tandartsen en rechtstreeks met Dentalab; Desmet brengt Verhaeghe mee.
    expect(keten.leden.length, 6);
    expect(keten.bevat(zoek('Tandtechniek Verhaeghe')), true);
    expect(keten.status, KetenStatus.bijna);
    expect(keten.nietMee, [zoek('Labo Dentalab')]);
  });

  test('tandarts zonder chirurg krijgt een eigen keten', () {
    Keten keten = opslag.ketens.firstWhere((k) => k.middelpunt == zoek('Dr. Jonas Martens'));
    expect(keten.leden, [zoek('Dr. Jonas Martens'), zoek('Smile Lab')]);
  });

  test('labo kan in meerdere ketens zitten', () {
    // Dentalab werkt met tandartsen van Janssens en van Willems.
    expect(opslag.ketensVan(zoek('Labo Dentalab')).length, 2);
  });

  test('een bezoek past de interesse aan', () {
    Contact maes = zoek('Dr. Tom Maes');
    opslag.voegBezoekToe(maes, Bezoek(datum: DateTime.now(), soort: Contactmoment.bezoek, interesseNa: Interesse.gebruiktBego));
    expect(maes.interesse, Interesse.gebruiktBego);
    expect(maes.langNietBezocht, false);
  });

  test('adres netjes opmaken uit een suggestie', () {
    Map<String, dynamic> huis = {
      'type': 'house', 'street': 'Grote Markt - Grand-Place', 'housenumber': '12',
      'postcode': '9600', 'city': 'Ronse - Renaix',
    };
    expect(maakAdresTekst(huis), 'Grote Markt 12, 9600 Ronse');
    Map<String, dynamic> straat = {'type': 'street', 'name': 'Stationsstraat', 'postcode': '9620', 'city': 'Zottegem'};
    expect(maakAdresTekst(straat), 'Stationsstraat, 9620 Zottegem');
  });

  testWidgets('merken: bestaande merken als suggestie, nieuw merk toevoegen', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const BegoApp());
    await tester.tap(find.text('Nieuw'));
    await tester.pumpAndSettle();

    Finder merkVeld = find.widgetWithText(TextField, 'Huidig implantaatmerk');
    await tester.ensureVisible(merkVeld);
    await tester.enterText(merkVeld, 'strau');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Straumann'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Straumann'), findsOneWidget);

    await tester.enterText(merkVeld, 'Osstem');
    await tester.pumpAndSettle();
    expect(find.text('Nieuw merk toevoegen: "Osstem"'), findsOneWidget);
    await tester.tap(find.text('Nieuw merk toevoegen: "Osstem"'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Osstem'), findsOneWidget);
    tester.view.reset();
  });

  testWidgets('gsm: app start op met tabbladen', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const BegoApp());
    expect(find.text('Opvolging'), findsOneWidget);

    await tester.tap(find.text('Contacten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr. An Peeters'));
    await tester.pumpAndSettle();
    expect(find.text('Bezoek noteren'), findsOneWidget);

    await tester.tap(find.text('Bewerken'));
    await tester.pumpAndSettle();
    expect(find.text('Contact bewerken'), findsOneWidget);
    tester.view.reset();
  });

  testWidgets('laptop: detailpaneel en formulieren openen', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const BegoApp());

    await tester.tap(find.text('Dr. An Peeters'));
    await tester.pumpAndSettle();
    expect(find.text('Bezoek noteren'), findsOneWidget);

    await tester.tap(find.text('Bezoek noteren'));
    await tester.pumpAndSettle();
    expect(find.text('Soort contact'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Partner'));
    await tester.pumpAndSettle();
    expect(find.text('Kies een partner'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Toon resultaten'), findsOneWidget);
    await tester.tap(find.text('Toon resultaten'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ketens (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Ontbreekt'), findsWidgets);

    // Hele keten op de kaart tonen: er verschijnt een balkje met de naam.
    await tester.tap(find.byTooltip('Toon op kaart').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('/6 mee'), findsOneWidget);

    await tester.tap(find.text('Opvolging'));
    await tester.pumpAndSettle();
    expect(find.text('Offerte sturen'), findsOneWidget);
    tester.view.reset();
  });
}
