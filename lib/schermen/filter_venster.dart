// Venster met extra filters: kleur, ketenstatus en lang niet bezocht.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/filters.dart';
import '../gegevens/keten.dart';
import '../onderdelen/kopje.dart';

class FilterVenster extends StatefulWidget {
  final Filters filters; // we passen dit object rechtstreeks aan

  const FilterVenster({super.key, required this.filters});

  @override
  State<FilterVenster> createState() => _FilterVensterState();
}

class _FilterVensterState extends State<FilterVenster> {
  @override
  Widget build(BuildContext context) {
    Filters filters = widget.filters;

    // Kleuren (interesse): je mag er meerdere aanvinken.
    List<Widget> interesseKnoppen = [];
    for (Interesse interesse in Interesse.values) {
      interesseKnoppen.add(FilterChip(
        avatar: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: interesseKleur(interesse), shape: BoxShape.circle),
        ),
        showCheckmark: false,
        label: Text(interesseTekst(interesse)),
        selected: filters.interesses.contains(interesse),
        onSelected: (aan) {
          setState(() {
            if (aan) {
              filters.interesses.add(interesse);
            } else {
              filters.interesses.remove(interesse);
            }
          });
        },
      ));
    }

    // Ketenstatus: maar één tegelijk (of "Alle").
    List<Widget> ketenKnoppen = [
      ChoiceChip(
        label: const Text('Alle'),
        selected: filters.ketenStatus == null,
        onSelected: (aan) => setState(() => filters.ketenStatus = null),
      ),
    ];
    for (KetenStatus status in KetenStatus.values) {
      ketenKnoppen.add(ChoiceChip(
        label: Text(ketenStatusTekst(status)),
        selected: filters.ketenStatus == status,
        onSelected: (aan) => setState(() => filters.ketenStatus = status),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(onPressed: () => setState(() => filters.wis()), child: const Text('Alles wissen')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
        kopje(context, 'Interesse in Bego'),
        Wrap(spacing: 8, runSpacing: 8, children: interesseKnoppen),
        kopje(context, 'Ketenstatus'),
        Wrap(spacing: 8, runSpacing: 8, children: ketenKnoppen),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Toont alleen contacten die in een keten met deze status zitten. '
            '"Bijna" = twee van de drie gebruiken Bego.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        kopje(context, 'Opvolging'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Alleen lang niet bezocht'),
          subtitle: const Text('Meer dan 3 maanden geleden, of nog nooit'),
          value: filters.alleenLangNietBezocht,
          onChanged: (aan) => setState(() => filters.alleenLangNietBezocht = aan),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Toon resultaten')),
      ]),
    );
  }
}
