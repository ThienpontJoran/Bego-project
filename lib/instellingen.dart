// Instellingen voor externe diensten.
// Alle sleutels staan in het bestand ".env" (dat niet op GitHub komt).
// Flutter leest ze in als je start met:
//   .flutter\bin\flutter.bat run -d chrome --dart-define-from-file=.env
// (of gewoon F5 in VS Code). Online komen ze uit de GitHub-geheimen.

// Supabase (database en inloggen).
// De "publishable key" mag in een website staan: de database laat alleen
// ingelogde gebruikers binnen (Row Level Security, zie supabase/database.sql).
const String supabaseAdres = String.fromEnvironment('SUPABASE_URL');
const String supabaseSleutel = String.fromEnvironment('SUPABASE_SLEUTEL');

// API-sleutel van CARTO (kaartachtergrond). Gratis tot 1 miljoen kaarttegels per maand.
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
