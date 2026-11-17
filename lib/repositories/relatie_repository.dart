// Leest en bewaart relaties in de tabel "relaties" van Supabase.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contact.dart';
import '../models/relatie.dart';

class RelatieRepository {
  SupabaseClient get database => Supabase.instance.client;

  // [contactVanId] = alle contacten, opgezocht op hun id.
  // In de database staat alleen het id van beide contacten; hier zoeken we de echte contacten erbij.
  Future<List<Relatie>> haalAlleOp(Map<String, Contact> contactVanId) async {
    List<Map<String, dynamic>> rijen = await database.from('relaties').select();
    List<Relatie> relaties = [];
    for (Map<String, dynamic> rij in rijen) {
      Contact? eerste = contactVanId[rij['eerste_id']];
      Contact? tweede = contactVanId[rij['tweede_id']];
      if (eerste == null || tweede == null) continue;

      Color? kleur;
      if (rij['kleur'] != null) kleur = Color(rij['kleur']);

      relaties.add(Relatie(
        eerste,
        tweede,
        id: rij['id'],
        bevestigd: rij['bevestigd'],
        opmerking: rij['opmerking'],
        kleur: kleur,
      ));
    }
    return relaties;
  }

  Future<void> bewaar(Relatie relatie) async {
    await database.from('relaties').upsert(relatie.naarDatabase());
  }

  Future<void> verwijder(Relatie relatie) async {
    await database.from('relaties').delete().eq('id', relatie.id);
  }
}
