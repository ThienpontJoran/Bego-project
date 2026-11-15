// Op een gsm opent het detailpaneel als aparte pagina.

import 'package:flutter/material.dart';

import '../gegevens/contact.dart';
import '../gegevens/opslag.dart';
import '../onderdelen/detail_paneel.dart';

class DetailPagina extends StatefulWidget {
  final Contact contact;

  const DetailPagina({super.key, required this.contact});

  @override
  State<DetailPagina> createState() => _DetailPaginaState();
}

class _DetailPaginaState extends State<DetailPagina> {
  // "late" = we geven het pas een waarde in initState, maar zeker voor we het gebruiken.
  late Contact contact;

  @override
  void initState() {
    super.initState();
    contact = widget.contact;
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder tekent de pagina opnieuw als er iets in de opslag verandert.
    return ListenableBuilder(
      listenable: opslag,
      builder: (context, child) {
        if (!opslag.contacten.contains(contact)) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Dit contact is verwijderd.')));
        }
        return Scaffold(
          appBar: AppBar(
            actions: [
              TextButton.icon(
                // Terug naar het hoofdscherm en dit contact op de kaart tonen.
                onPressed: () => Navigator.pop(context, contact),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Op kaart'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: DetailPaneel(
            contact: contact,
            onKiesPartner: (partner) => setState(() => contact = partner),
          ),
        );
      },
    );
  }
}
