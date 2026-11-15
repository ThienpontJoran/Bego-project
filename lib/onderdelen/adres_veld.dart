// Adresveld met suggesties terwijl je typt. Klik op een suggestie en het
// adres is meteen ingevuld en op de kaart gezet.

import 'package:flutter/material.dart';

import '../gegevens/adres_zoeker.dart';

class AdresVeld extends StatefulWidget {
  final TextEditingController controller;
  final void Function(AdresSuggestie suggestie) onGekozen;
  final String? Function(String? waarde) validator;

  const AdresVeld({super.key, required this.controller, required this.onGekozen, required this.validator});

  @override
  State<AdresVeld> createState() => _AdresVeldState();
}

class _AdresVeldState extends State<AdresVeld> {
  FocusNode focus = FocusNode();
  int zoekNummer = 0; // om oude zoekopdrachten te negeren
  AdresSuggestie? gekozen;
  bool bezig = false; // true terwijl we de plek van de gekozen suggestie opzoeken

  // Klik op een suggestie: zoek (indien nodig) de exacte plek op.
  Future<void> kies(AdresSuggestie suggestie) async {
    setState(() {
      gekozen = suggestie;
      bezig = true;
    });
    if (suggestie.plaats == null) {
      suggestie.plaats = await zoekAdres(suggestie.tekst);
    }
    if (!mounted) return;
    setState(() => bezig = false);
    widget.onGekozen(suggestie);
  }

  // Wordt opgeroepen telkens de tekst verandert.
  Future<List<AdresSuggestie>> suggesties(TextEditingValue waarde) async {
    String tekst = waarde.text.trim();
    if (tekst.length < 3) return [];

    // Even wachten: typt de gebruiker nog verder, dan zoeken we nog niet.
    zoekNummer++;
    int mijnNummer = zoekNummer;
    await Future.delayed(const Duration(milliseconds: 350));
    if (mijnNummer != zoekNummer) return [];

    // Net een suggestie gekozen? Dan niet opnieuw zoeken.
    if (gekozen != null && gekozen!.tekst == tekst) return [];

    return zoekSuggesties(tekst);
  }

  @override
  Widget build(BuildContext context) {
    // RawAutocomplete = een tekstveld met een lijstje suggesties eronder.
    return RawAutocomplete<AdresSuggestie>(
      textEditingController: widget.controller,
      focusNode: focus,
      optionsBuilder: suggesties,
      displayStringForOption: (suggestie) => suggestie.tekst,
      onSelected: kies,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        String hulptekst = 'Begin te typen en kies een suggestie';
        Widget? vinkje;
        if (gekozen != null && gekozen!.tekst == controller.text.trim()) {
          if (bezig) {
            hulptekst = 'Locatie zoeken...';
          } else if (gekozen!.plaats != null) {
            hulptekst = 'Locatie gevonden';
            vinkje = const Icon(Icons.check_circle, color: Color(0xFF2E7D32));
          } else {
            hulptekst = 'Locatie niet gevonden, controleer het adres';
          }
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: widget.validator,
          onChanged: (tekst) => setState(() {}), // hulptekst bijwerken
          decoration: InputDecoration(
            labelText: 'Adres *',
            hintText: 'Bv. Markt 12, Oudenaarde',
            helperText: hulptekst,
            prefixIcon: const Icon(Icons.place_outlined),
            suffixIcon: vinkje,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, opties) {
        List<Widget> regels = [];
        for (AdresSuggestie suggestie in opties) {
          Widget? onder;
          if (suggestie.naam != '') onder = Text(suggestie.naam);
          regels.add(ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(suggestie.tekst),
            subtitle: onder,
            onTap: () => onSelected(suggestie),
          ));
        }
        return suggestieKader(regels);
      },
    );
  }
}

// Het witte kader met suggesties onder een tekstveld (ook gebruikt voor merken).
Widget suggestieKader(List<Widget> regels) {
  return Align(
    alignment: Alignment.topLeft,
    child: Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), shrinkWrap: true, children: regels),
      ),
    ),
  );
}
