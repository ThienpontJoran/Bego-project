// Instellingen voor externe diensten.

// API-sleutel van CARTO (kaartachtergrond). Gratis tot 1 miljoen kaarttegels per maand.
// De sleutel staat NIET in de code, maar in het bestand ".env" (dat niet op GitHub komt).
// Flutter leest het in als je start met:
//   .flutter\bin\flutter.bat run -d chrome --dart-define-from-file=.env
// Let op: in de gebouwde website is de sleutel wel zichtbaar voor wie goed zoekt
// (dat is normaal voor kaartsleutels in een website).
const String cartoSleutel = String.fromEnvironment('CARTO_SLEUTEL');

// De kaart bestaat uit twee lagen van CARTO "Positron" (licht en rustig):
// 1. de achtergrond zonder plaatsnamen (onder onze lijnen en vormen);
// 2. alleen de plaatsnamen (bovenop onze vormen, zodat je ze altijd kan lezen).
// {r} wordt "@2x" op scherpe schermen (zoals een MacBook), anders leeg.
final String kaartZonderNamen = kaartAdres('light_nolabels');
final String kaartAlleenNamen = kaartAdres('light_only_labels');

// Maakt het adres van een kaartlaag. Zonder sleutel laten we "?key=" gewoon weg.
String kaartAdres(String laag) {
  String adres = 'https://basemaps.cartocdn.com/rastertiles/$laag/{z}/{x}/{y}{r}.png';
  if (cartoSleutel.isEmpty) return adres;
  return '$adres?key=$cartoSleutel';
}
