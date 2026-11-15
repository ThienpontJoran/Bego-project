// Kleine tests. Uitvoeren met: .flutter\bin\flutter.bat test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bego_netwerkkaart/contact.dart';
import 'package:bego_netwerkkaart/main.dart';
import 'package:bego_netwerkkaart/testgegevens.dart';

void main() {
  test('partners werken in beide richtingen', () {
    List<Contact> partners = zoekPartners(peeters, alleRelaties);
    expect(partners, containsAll([janssens, dentalab, deVos]));
  });

  testWidgets('app start met titel', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KaartPagina()));
    expect(find.text('Bego Netwerkkaart – testversie'), findsOneWidget);
  });
}
