// Merken kiezen: gekozen merken staan als "chips" bovenaan.
// Typ je in het veld, dan verschijnen de merken die al bestaan; klik er een aan.
// Bestaat het merk nog niet, dan kan je het als nieuw merk toevoegen.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/hulpfuncties.dart';
import '../gegevens/opslag.dart';
import 'adres_veld.dart';

class MerkenKiezer extends StatefulWidget {
  final List<String> merken; // deze lijst passen we rechtstreeks aan

  const MerkenKiezer({super.key, required this.merken});

  @override
  State<MerkenKiezer> createState() => _MerkenKiezerState();
}

class _MerkenKiezerState extends State<MerkenKiezer> {
  TextEditingController tekstveld = TextEditingController();
  FocusNode focus = FocusNode();

  // Alle merken die al bij een contact ingevuld zijn, alfabetisch.
  List<String> bekendeMerken() {
    List<String> alle = [];
    for (Contact contact in opslag.contacten) {
      for (String merk in contact.merken) {
        if (!alle.contains(merk)) alle.add(merk);
      }
    }
    alle.sort();
    return alle;
  }

  // Zoekt een bestaand merk met dezelfde naam (hoofdletters maken niet uit).
  String? bestaandMerk(String naam) {
    for (String merk in bekendeMerken()) {
      if (merk.toLowerCase() == naam.toLowerCase()) return merk;
    }
    return null;
  }

  List<String> suggesties(TextEditingValue waarde) {
    String zoek = waarde.text.trim();
    List<String> resultaat = [];
    for (String merk in bekendeMerken()) {
      if (widget.merken.contains(merk)) continue; // al gekozen
      if (zoek == '' || maakZoekbaar(merk).contains(maakZoekbaar(zoek))) {
        resultaat.add(merk);
      }
    }
    // Getypt merk bestaat nog niet? Dan kan je het als nieuw toevoegen.
    if (zoek != '' && bestaandMerk(zoek) == null) {
      resultaat.add(zoek);
    }
    return resultaat;
  }

  void voegToe(String merk) {
    merk = merk.trim();
    if (merk == '') return;
    // Bestaat het al (bv. "straumann")? Gebruik dan de bestaande schrijfwijze.
    String? bestaand = bestaandMerk(merk);
    if (bestaand != null) merk = bestaand;

    setState(() {
      if (!widget.merken.contains(merk)) widget.merken.add(merk);
    });
    tekstveld.clear();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> chips = [];
    for (String merk in widget.merken) {
      chips.add(InputChip(
        label: Text(merk),
        onDeleted: () => setState(() => widget.merken.remove(merk)),
      ));
    }

    List<Widget> delen = [];
    if (chips.isNotEmpty) {
      delen.add(Wrap(spacing: 8, runSpacing: 8, children: chips));
      delen.add(const SizedBox(height: 10));
    }

    delen.add(RawAutocomplete<String>(
      textEditingController: tekstveld,
      focusNode: focus,
      optionsBuilder: suggesties,
      onSelected: voegToe,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (tekst) => onFieldSubmitted(), // Enter = eerste suggestie kiezen
          decoration: const InputDecoration(
            labelText: 'Huidig implantaatmerk',
            hintText: 'Typ of kies een merk',
            prefixIcon: Icon(Icons.sell_outlined),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, opties) {
        List<String> bekend = bekendeMerken();
        List<Widget> regels = [];
        for (String merk in opties) {
          if (bekend.contains(merk)) {
            regels.add(ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(merk),
              onTap: () => onSelected(merk),
            ));
          } else {
            regels.add(ListTile(
              leading: const Icon(Icons.add),
              title: Text('Nieuw merk toevoegen: "$merk"'),
              onTap: () => onSelected(merk),
            ));
          }
        }
        return suggestieKader(regels);
      },
    ));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: delen);
  }
}
