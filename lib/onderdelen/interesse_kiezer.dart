// Knopjes om de interesse in Bego te kiezen, elk met zijn kleur.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';

class InteresseKiezer extends StatelessWidget {
  final Interesse waarde;
  final void Function(Interesse interesse) onKies;

  const InteresseKiezer({super.key, required this.waarde, required this.onKies});

  @override
  Widget build(BuildContext context) {
    List<Widget> knoppen = [];
    for (Interesse interesse in Interesse.values) {
      knoppen.add(ChoiceChip(
        showCheckmark: false,
        avatar: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: interesseKleur(interesse), shape: BoxShape.circle),
        ),
        label: Text(interesseTekst(interesse)),
        selected: interesse == waarde,
        onSelected: (aan) => onKies(interesse),
      ));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: knoppen);
  }
}
