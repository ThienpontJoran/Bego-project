// Laat de browser een bestand downloaden.
// Op het web gebruiken we download_web.dart. In de tests (geen browser) gebruiken we
// download_geen_web.dart, dat niets doet. Dart kiest zelf het juiste bestand.

export 'download_geen_web.dart' if (dart.library.js_interop) 'download_web.dart';
