// Hoe een bezoek (of telefoontje, e-mail, beurs) eruitziet.
// Een bezoek wordt bewaard in de tabel "bezoeken" in Supabase.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'contact.dart';

// Hoe je iemand gesproken hebt.
enum Contactmoment { bezoek, telefoon, email, beurs }

class Bezoek {
  String id; // uniek nummer in de database
  DateTime datum;
  Contactmoment soort;
  String verslag;
  String volgendeStap; // leeg = geen volgende stap
  DateTime? volgendeStapDatum; // null = geen datum gekozen
  Interesse interesseNa;

  Bezoek({
    String? id,
    required this.datum,
    required this.soort,
    required this.interesseNa,
    this.verslag = '',
    this.volgendeStap = '',
    this.volgendeStapDatum,
  }) : id = id ?? const Uuid().v4();

  // ---------- Van en naar de database ----------

  // Datums bewaren we in UTC (wereldtijd) en zetten we bij het lezen terug naar Belgische tijd.
  static Bezoek vanDatabase(Map<String, dynamic> rij) {
    DateTime? stapDatum;
    if (rij['volgende_stap_datum'] != null) {
      stapDatum = DateTime.parse(rij['volgende_stap_datum']).toLocal();
    }
    return Bezoek(
      id: rij['id'],
      datum: DateTime.parse(rij['datum']).toLocal(),
      soort: Contactmoment.values.byName(rij['soort']),
      verslag: rij['verslag'],
      volgendeStap: rij['volgende_stap'],
      volgendeStapDatum: stapDatum,
      interesseNa: Interesse.values.byName(rij['interesse_na']),
    );
  }

  // [contact] = bij wie het bezoek hoort.
  Map<String, dynamic> naarDatabase(Contact contact) {
    return {
      'id': id,
      'contact_id': contact.id,
      'datum': datum.toUtc().toIso8601String(),
      'soort': soort.name,
      'verslag': verslag,
      'volgende_stap': volgendeStap,
      'volgende_stap_datum': volgendeStapDatum?.toUtc().toIso8601String(),
      'interesse_na': interesseNa.name,
    };
  }
}

// ---------- Teksten en icoontjes ----------

String contactmomentTekst(Contactmoment moment) {
  switch (moment) {
    case Contactmoment.bezoek:
      return 'Bezoek';
    case Contactmoment.telefoon:
      return 'Telefoon';
    case Contactmoment.email:
      return 'E-mail';
    case Contactmoment.beurs:
      return 'Beurs';
  }
}

IconData contactmomentIcoon(Contactmoment moment) {
  switch (moment) {
    case Contactmoment.bezoek:
      return Icons.directions_car_outlined;
    case Contactmoment.telefoon:
      return Icons.phone_outlined;
    case Contactmoment.email:
      return Icons.mail_outline;
    case Contactmoment.beurs:
      return Icons.storefront_outlined;
  }
}
