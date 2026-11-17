// Startpunt van de app: stelt de stijl en de taal in en opent het hoofdscherm.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'instellingen.dart';
import 'schermen/inlog_scherm.dart';
import 'utils/kleuren.dart';

// "async" omdat we eerst moeten wachten tot de verbinding met Supabase klaar is.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseAdres.isEmpty || supabaseSleutel.isEmpty) {
    runApp(const MaterialApp(
      home: Scaffold(body: Center(child: Text('SUPABASE_URL of SUPABASE_SLEUTEL ontbreekt in .env'))),
    ));
    return;
  }

  await Supabase.initialize(url: supabaseAdres, anonKey: supabaseSleutel);
  runApp(const BegoApp());
}

class BegoApp extends StatelessWidget {
  // Het eerste scherm. Normaal de inlogpoort; de tests openen meteen het hoofdscherm.
  final Widget beginScherm;

  const BegoApp({super.key, this.beginScherm = const InlogPoort()});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bego Netwerkkaart',
      debugShowCheckedModeBanner: false,
      theme: maakThema(),
      // Nederlandstalige kalender en knoppen.
      locale: const Locale('nl', 'BE'),
      supportedLocales: const [Locale('nl', 'BE')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: beginScherm,
    );
  }
}

// De stijl van de hele app: kleuren, afgeronde hoeken, invulvelden.
ThemeData maakThema() {
  // Wit en grijs, met geel voor de knoppen (zoals het logo van Bego).
  // "monochrome" = alle achtergronden zuiver wit/grijs, zonder een geel of beige tintje.
  ColorScheme kleuren = ColorScheme.fromSeed(
    seedColor: begoGrijs,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    primary: begoGeel,
    onPrimary: const Color(0xFF1F1F1F),
    surface: Colors.white,
    primaryContainer: const Color(0xFFEEEEEE), // achtergrond van het gekozen contact in de lijst
    onPrimaryContainer: const Color(0xFF1F1F1F),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: kleuren,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(backgroundColor: kleuren.surface, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: kleuren.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: kleuren.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kleuren.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kleuren.outlineVariant),
      ),
    ),
    // Gele tekst op wit is slecht leesbaar: tekst-knoppen en gekozen regels worden donkergrijs.
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: begoDonkergrijs)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: begoDonkergrijs)),
    listTileTheme: const ListTileThemeData(selectedColor: Color(0xFF1F1F1F)),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
  );
}
