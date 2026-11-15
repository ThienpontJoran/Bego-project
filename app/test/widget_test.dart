import 'package:flutter_test/flutter_test.dart';

import 'package:bego_netwerkkaart/data.dart';
import 'package:bego_netwerkkaart/main.dart';

void main() {
  test('partners werken in beide richtingen', () {
    final peeters = contacts.firstWhere((c) => c.name == 'Dr. An Peeters');
    final names = partnersOf(peeters).map((c) => c.name).toSet();
    expect(names, containsAll(['Chirurg Janssens', 'Labo Dentalab', 'Chirurg De Vos']));
  });

  testWidgets('app start met titel', (tester) async {
    await tester.pumpWidget(const BegoApp());
    expect(find.text('Bego Netwerkkaart – testversie'), findsOneWidget);
  });
}
