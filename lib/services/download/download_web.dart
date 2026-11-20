// Downloaden in de browser: we maken een onzichtbare link naar het bestand en klikken erop.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadBestand(List<int> inhoud, String bestandsnaam) {
  Uint8List bytes = Uint8List.fromList(inhoud);
  web.Blob blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  );
  String adres = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement link = web.HTMLAnchorElement()
    ..href = adres
    ..download = bestandsnaam;
  link.click();
  web.URL.revokeObjectURL(adres);
}
