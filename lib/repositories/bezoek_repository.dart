// Leest en bewaart bezoeken in de tabel "bezoeken" van Supabase.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bezoek.dart';
import '../models/contact.dart';

class BezoekRepository {
  SupabaseClient get database => Supabase.instance.client;

  // Haalt alle bezoeken op en hangt elk bezoek aan het juiste contact.
  // [contactVanId] = alle contacten, opgezocht op hun id.
  Future<void> haalAlleOp(Map<String, Contact> contactVanId) async {
    List<Map<String, dynamic>> rijen = await database.from('bezoeken').select();
    for (Map<String, dynamic> rij in rijen) {
      Contact? contact = contactVanId[rij['contact_id']];
      if (contact != null) {
        contact.bezoeken.add(Bezoek.vanDatabase(rij));
      }
    }
  }

  Future<void> bewaar(Contact contact, Bezoek bezoek) async {
    await database.from('bezoeken').upsert(bezoek.naarDatabase(contact));
  }

  Future<void> verwijder(Bezoek bezoek) async {
    await database.from('bezoeken').delete().eq('id', bezoek.id);
  }
}
