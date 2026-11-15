import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'data.dart';
import 'shapes.dart';

void main() => runApp(const BegoApp());

class BegoApp extends StatelessWidget {
  const BegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bego Netwerkkaart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1B5E20), useMaterial3: true),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Contact? selected;

  bool isActive(Contact c) {
    if (selected == null) return true;
    return c == selected || partnersOf(selected!).contains(c);
  }

  bool touchesSelected(Relation r) => r.a == selected || r.b == selected;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    final map = _buildMap();
    final panel = selected == null ? null : DetailPanel(
      contact: selected!,
      onClose: () => setState(() => selected = null),
      onSelect: (c) => setState(() => selected = c),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bego Netwerkkaart – testversie')),
      body: wide
          ? Row(children: [
              Expanded(child: map),
              if (panel != null) SizedBox(width: 360, child: panel),
            ])
          : Column(children: [
              Expanded(child: map),
              if (panel != null) SizedBox(height: 320, child: panel),
            ]),
    );
  }

  Widget _buildMap() {
    return Stack(children: [
      FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(50.95, 3.75),
          initialZoom: 9.5,
          onTap: (_, _) => setState(() => selected = null),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'be.bego.netwerkkaart',
          ),
          PolylineLayer(polylines: [
            for (final r in relations)
              Polyline(
                points: [r.a.location, r.b.location],
                strokeWidth: touchesSelected(r) ? 4 : 2,
                color: selected == null
                    ? Colors.black54
                    : touchesSelected(r)
                        ? Colors.black87
                        : Colors.black12,
                pattern: r.confirmed
                    ? const StrokePattern.solid()
                    : StrokePattern.dashed(segments: const [8, 6]),
              ),
          ]),
          MarkerLayer(markers: [
            for (final c in contacts)
              Marker(
                point: c.location,
                width: 28,
                height: 28,
                child: GestureDetector(
                  onTap: () => setState(() => selected = c),
                  child: Tooltip(
                    message: c.name,
                    child: ContactIcon(
                      type: c.type,
                      color: isActive(c) ? c.interest.color : Colors.grey.shade300,
                      size: 24,
                      highlighted: c == selected,
                    ),
                  ),
                ),
              ),
          ]),
          const RichAttributionWidget(attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ]),
        ],
      ),
      const Positioned(left: 12, top: 12, child: Legend()),
    ]);
  }
}

class Legend extends StatelessWidget {
  const Legend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final t in ContactType.values)
            _row(ContactIcon(type: t, color: Colors.black54, size: 14), t.label),
          const Divider(),
          for (final i in Interest.values)
            _row(ContactIcon(type: ContactType.chirurg, color: i.color, size: 14), i.label),
        ]),
      ),
    );
  }

  Widget _row(Widget icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class DetailPanel extends StatelessWidget {
  const DetailPanel({super.key, required this.contact, required this.onClose, required this.onSelect});

  final Contact contact;
  final VoidCallback onClose;
  final ValueChanged<Contact> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = contact;
    final partners = partnersOf(c);
    final text = Theme.of(context).textTheme;

    return Material(
      elevation: 4,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          ContactIcon(type: c.type, color: c.interest.color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(c.name, style: text.titleLarge)),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ]),
        Text('${c.type.label} · ${c.interest.label}', style: text.bodyMedium),
        if (c.practice != null) Text(c.practice!, style: text.bodySmall),
        const SizedBox(height: 12),
        Text(c.address),
        if (c.brand != null) Text('Huidig merk: ${c.brand}'),
        if (c.notes != null) ...[
          const SizedBox(height: 8),
          Text(c.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
        const Divider(height: 24),
        Text('Partners', style: text.titleMedium),
        for (final type in ContactType.values)
          for (final p in partners.where((p) => p.type == type))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: ContactIcon(type: p.type, color: p.interest.color, size: 18),
              title: Text(p.name),
              subtitle: Text('${p.type.label} · ${p.interest.label}'),
              onTap: () => onSelect(p),
            ),
        if (partners.isEmpty) const Text('Nog geen partners'),
      ]),
    );
  }
}
