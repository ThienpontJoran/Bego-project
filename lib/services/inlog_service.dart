// Inloggen en uitloggen via Supabase.
// Accounts maak je zelf aan in Supabase (Authentication > Users).
// Registreren via de app kan niet: zo kunnen alleen de mensen die jij toevoegt erin.

import 'package:supabase_flutter/supabase_flutter.dart';

class InlogService {
  GoTrueClient get auth => Supabase.instance.client.auth;

  bool get isIngelogd => auth.currentSession != null;

  // Laat weten wanneer iemand in- of uitlogt.
  Stream<AuthState> get veranderingen => auth.onAuthStateChange;

  // Gooit een AuthException als het e-mailadres of wachtwoord niet klopt.
  Future<void> logIn(String email, String wachtwoord) async {
    await auth.signInWithPassword(email: email, password: wachtwoord);
  }

  Future<void> logUit() async {
    await auth.signOut();
  }
}

// Eén gedeelde inlogservice voor de hele app.
InlogService inlogService = InlogService();
