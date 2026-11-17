// Eén regel in een lijst: icoon, naam en een korte omschrijving.

import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../utils/hulpfuncties.dart';
import 'vorm.dart';

class ContactRegel extends StatelessWidget {
  final Contact contact;
  final void Function() onTap;
  final bool gekozen;
  final String? onderschrift; // null = standaard (praktijk of type + gemeente)
  final Widget? rechts; // iets extra aan de rechterkant

  const ContactRegel({
    super.key,
    required this.contact,
    required this.onTap,
    this.gekozen = false,
    this.onderschrift,
    this.rechts,
  });

  @override
  Widget build(BuildContext context) {
    String tekstOnder = '';
    if (onderschrift != null) {
      tekstOnder = onderschrift!;
    } else if (contact.praktijk != '') {
      tekstOnder = '${contact.praktijk} · ${gemeenteVan(contact.adres)}';
    } else {
      tekstOnder = '${soortTekst(contact.soort)} · ${gemeenteVan(contact.adres)}';
    }

    return ListTile(
      selected: gekozen,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Vorm(soort: contact.soort, kleur: interesseKleur(contact.interesse), grootte: 22),
      title: Text(contact.naam, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(tekstOnder, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: rechts,
      onTap: onTap,
    );
  }
}
