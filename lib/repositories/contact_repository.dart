// Leest en bewaart contacten in de tabel "contacten" van Supabase.
// Een repository is de enige plek die met de database praat over contacten.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contact.dart';

class ContactRepository {
  // De verbinding met Supabase (wordt in main.dart klaargezet).
  SupabaseClient get database => Supabase.instance.client;

  Future<List<Contact>> haalAlleOp() async {
    List<Map<String, dynamic>> rijen = await database.from('contacten').select();
    List<Contact> contacten = [];
    for (Map<String, dynamic> rij in rijen) {
      contacten.add(Contact.vanDatabase(rij));
    }
    return contacten;
  }

  // "upsert" = toevoegen als het id nog niet bestaat, anders aanpassen.
  // Zo heb je maar één functie nodig voor nieuw én bewerken.
  Future<void> bewaar(Contact contact) async {
    await database.from('contacten').upsert(contact.naarDatabase());
  }

  // De database verwijdert zijn bezoeken en relaties automatisch mee ("on delete cascade").
  Future<void> verwijder(Contact contact) async {
    await database.from('contacten').delete().eq('id', contact.id);
  }
}
