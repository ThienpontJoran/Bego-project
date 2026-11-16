// Het kadertje op de kaart dat uitlegt wat vormen, kleuren en lijnen betekenen.
// Je kan het open- en dichtklappen.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import 'vorm.dart';

class Legende extends StatefulWidget {
  final bool beginOpen;

  const Legende({super.key, this.beginOpen = true});

  @override
  State<Legende> createState() => _LegendeState();
}

class _LegendeState extends State<Legende> {
  bool open = true;

  @override
  void initState() {
    super.initState();
    open = widget.beginOpen;
  }

  @override
  Widget build(BuildContext context) {
    IconData pijl = Icons.expand_less;
    if (open) pijl = Icons.expand_more;

    List<Widget> regels = [
      InkWell(
        onTap: () => setState(() => open = !open),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 6),
          const Text('Legende', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(pijl, size: 18),
        ]),
      ),
    ];

    if (open) {
      regels.add(const SizedBox(height: 8));
      for (Soort soort in Soort.values) {
        regels.add(regel(Vorm(soort: soort, kleur: Colors.blueGrey, grootte: 14), soortTekst(soort)));
      }
      regels.add(const Divider(height: 14));
      for (Interesse interesse in Interesse.values) {
        Widget bolletje = Vorm(soort: Soort.chirurg, kleur: interesseKleur(interesse), grootte: 14);
        regels.add(regel(bolletje, interesseTekst(interesse)));
      }
      regels.add(const Divider(height: 14));
      regels.add(regel(lijntje(false), 'Werken samen'));
      regels.add(regel(lijntje(true), 'Vermoed'));
      regels.add(const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Klik op een lijn om ze\neen kleur te geven', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: regels,
        ),
      ),
    );
  }

  Widget regel(Widget icoon, String tekst) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 18, child: Center(child: icoon)),
        const SizedBox(width: 8),
        Text(tekst, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  // Een kort lijntje: doorgetrokken of met stippen.
  Widget lijntje(bool gestippeld) {
    if (!gestippeld) {
      return Container(width: 18, height: 2, color: Colors.blueGrey);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 2, color: Colors.blueGrey),
      const SizedBox(width: 2),
      Container(width: 5, height: 2, color: Colors.blueGrey),
      const SizedBox(width: 2),
      Container(width: 4, height: 2, color: Colors.blueGrey),
    ]);
  }
}
