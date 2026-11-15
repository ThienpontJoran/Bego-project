import 'package:flutter/material.dart';

import 'data.dart';

/// Cirkel = chirurg, vierkant = tandarts, driehoek = labo.
class ContactIcon extends StatelessWidget {
  const ContactIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 20,
    this.highlighted = false,
  });

  final ContactType type;
  final Color color;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ShapePainter(type, color, highlighted),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.type, this.color, this.highlighted);

  final ContactType type;
  final Color color;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path();
    switch (type) {
      case ContactType.chirurg:
        path.addOval(Rect.fromLTWH(1, 1, w - 2, w - 2));
      case ContactType.tandarts:
        path.addRect(Rect.fromLTWH(2, 2, w - 4, w - 4));
      case ContactType.labo:
        path
          ..moveTo(w / 2, 1)
          ..lineTo(w - 1, w - 2)
          ..lineTo(1, w - 2)
          ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 3 : 1.2
        ..color = highlighted ? Colors.blue.shade800 : Colors.black87,
    );
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.type != type || old.color != color || old.highlighted != highlighted;
}
