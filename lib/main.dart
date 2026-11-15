// Startpunt van de app: stelt de stijl en de taal in en opent het hoofdscherm.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'schermen/hoofdscherm.dart';

void main() {
  runApp(const BegoApp());
}

class BegoApp extends StatelessWidget {
  const BegoApp({super.key});

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
      home: const Hoofdscherm(),
    );
  }
}

// De stijl van de hele app: kleuren, afgeronde hoeken, invulvelden.
ThemeData maakThema() {
  ColorScheme kleuren = ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E69));

  return ThemeData(
    useMaterial3: true,
    colorScheme: kleuren,
    scaffoldBackgroundColor: kleuren.surfaceContainerLow,
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
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
  );
}
