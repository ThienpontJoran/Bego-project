// Instellingen voor externe diensten.

// API-sleutel van CARTO (kaartachtergrond). Gratis tot 1 miljoen kaarttegels per maand.
// Let op: deze sleutel is zichtbaar voor iedereen die de website opent (dat is normaal
// voor kaartsleutels in een website).
const String cartoSleutel = 'cb1_59zs_1_1f0593e4585a70208d74f7c5';

// De kaart bestaat uit twee lagen van CARTO "Positron" (licht en rustig):
// 1. de achtergrond zonder plaatsnamen (onder onze lijnen en vormen);
// 2. alleen de plaatsnamen (bovenop onze vormen, zodat je ze altijd kan lezen).
// {r} wordt "@2x" op scherpe schermen (zoals een MacBook), anders leeg.
const String kaartZonderNamen =
    'https://basemaps.cartocdn.com/rastertiles/light_nolabels/{z}/{x}/{y}{r}.png?key=$cartoSleutel';
const String kaartAlleenNamen =
    'https://basemaps.cartocdn.com/rastertiles/light_only_labels/{z}/{x}/{y}{r}.png?key=$cartoSleutel';
